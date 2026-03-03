const mongoose = require('mongoose');

const submissionSchema = new mongoose.Schema({
    assignmentId: { type: String, required: true },
    studentId: { type: String, required: true },
    studentName: { type: String, required: true },
    content: { type: String },
    fileName: { type: String },
    fileUrl: { type: String },
    submittedAt: { type: Date, default: Date.now },
    score: { type: Number },
    feedback: { type: String },
    status: { type: String, default: 'submitted' }
});

module.exports = mongoose.model('Submission', submissionSchema);
