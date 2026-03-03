const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
  _id: { type: String, default: () => new mongoose.Types.ObjectId().toString() },
  topicId: { type: String, required: true },
  questionText: { type: String, required: true },
  type: { type: String, enum: ['quiz', 'coding'], default: 'quiz' },
  codeSnippet: { type: String }, // For quiz type
  options: [{ type: String }], // For quiz type
  correctOptionIndex: { type: Number }, // For quiz type
  explanation: { type: String },
  order: { type: Number },

  // Coding specific fields
  starterCode: { type: String },
  constraints: { type: String },
  difficulty: { type: String, enum: ['easy', 'medium', 'hard'], default: 'medium' },
  testCases: [{
    input: { type: String },
    output: { type: String },
    isHidden: { type: Boolean, default: false }
  }]
});

module.exports = mongoose.model('Question', questionSchema);
