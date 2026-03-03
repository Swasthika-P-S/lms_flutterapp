const mongoose = require('mongoose');

const AssignmentSchema = new mongoose.Schema({
    courseId: { type: String, required: true },
    title: { type: String, required: true },
    description: { type: String, required: true },
    deadline: { type: Date, required: true },
    maxScore: { type: Number, default: 100 },
    createdAt: { type: Date, default: Date.now },
    createdBy: { type: String, required: true }
});

module.exports = mongoose.model('Assignment', AssignmentSchema);
