const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const bodyParser = require("body-parser");
const { GoogleGenAI } = require("@google/genai");
require("dotenv").config();

const ai = new GoogleGenAI({
  apiKey: process.env.GOOGLE_API_KEY,
});

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.use((req, res, next) => {
  console.log("Headers:", req.headers);
  console.log("Body:", req.body);
  next();
});

// ======================= DATABASE SETUP =========================
mongoose.connect(process.env.MONGODB_URI);

// ======================= SCHEMAS =========================
const UserSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  photoUrl: String,
  dndLogs: [
    {
      turnedOnAt: Date,
      turnedOffAt: Date,
      locationOn: {
        latitude: Number,
        longitude: Number,
      },
      locationOff: {
        latitude: Number,
        longitude: Number,
      },
    },
  ],
});
const User = mongoose.model("User", UserSchema);

const MissedCallSchema = new mongoose.Schema({
  name: String,
  number: String,
  timestamp: Number,
  status: { type: String, enum: ["missed", "incoming"], default: "missed" },
});
const MissedCall = mongoose.model("MissedCall", MissedCallSchema);

// ======================= WHATSAPP + AI =========================

// ======================= ROUTES =========================

app.post("/api/users", async (req, res) => {
  try {
    const { name, email, photoUrl } = req.body;
    await User.updateOne({ email }, { name, photoUrl }, { upsert: true });
    res.send("✅ User saved");
  } catch (error) {
    console.error("Error saving user:", error);
    res.status(500).send("❌ Failed to save user");
  }
});

app.post("/api/log-dnd", async (req, res) => {
  const { email, action, timestamp, location } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(404).send("User not found");

    let logs = user.dndLogs;

    if (action === "on") {
      logs.push({
        turnedOnAt: new Date(parseInt(timestamp)),
        locationOn: location,
      });
    } else if (action === "off" && logs.length > 0) {
      const last = logs[logs.length - 1];
      if (!last.turnedOffAt) {
        last.turnedOffAt = new Date(parseInt(timestamp));
        last.locationOff = location;
      }
    }

    await user.save();
    res.send("✅ DND log updated");
  } catch (err) {
    console.error("DND logging error:", err);
    res.status(500).send("Server error");
  }
});

app.post("/api/missed-calls", async (req, res) => {
  try {
    const { name = null, number, timestamp, status = "missed" } = req.body;
    if (!number || !timestamp)
      return res.status(400).send("Missing number or timestamp");

    const missedCall = new MissedCall({ name, number, timestamp, status });
    await missedCall.save();

    await sendWhatsAppMessage(number, name);
    res.send("📞 Missed call logged & WhatsApp sent");
  } catch (error) {
    console.error("Error logging missed call:", error);
    res.status(500).send("❌ Failed to log missed call");
  }
});

app.get("/api/missed-calls", async (req, res) => {
  try {
    const missedCalls = await MissedCall.find().sort({ timestamp: -1 });
    res.status(200).json(missedCalls);
  } catch (err) {
    console.error("Error fetching missed calls:", err);
    res.status(500).send("Failed to fetch missed calls");
  }
});

app.get("/api/users/email/:email", async (req, res) => {
  const email = req.params.email;
  try {
    const user = await User.findOne({ email });
    if (user) {
      res.status(200).json(user);
    } else {
      res.status(404).send("User not found");
    }
  } catch (err) {
    res.status(500).send("Server error");
  }
});

app.post("/api/check-emergency", async (req, res) => {
  const { text } = req.body;

  try {
    const result = await ai.models.generateContent({
      model: "gemini-2.0-flash",
      contents: [
        {
          role: "user",
          parts: [
            {
              text: `Is this message an emergency? Reply only with true or false:\n"${text}"`,
            },
          ],
        },
      ],
    });

    console.log("🤖 Gemini reply:", result.text);
    if (result.text?.toLowerCase().includes("true")) {
      return res.sendStatus(200); // Emergency
    } else {
      return res.sendStatus(204); // Not an emergency
    }
  } catch (err) {
    console.error("Gemini error", err);
    res.sendStatus(500);
  }
});

// ======================= START SERVER =========================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
