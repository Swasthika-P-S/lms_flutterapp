require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const Course = require('./models/Course');
const Topic = require('./models/Topic');
const Question = require('./models/Question');
const Assignment = require('./models/Assignment');
const Submission = require('./models/Submission');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
const PORT = process.env.PORT || 5000;

// Gemini AI Initialization
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({
    model: 'gemini-1.5-flash-latest',
    generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
    }
});

app.use(cors());
app.use(express.json());

// Logger middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
    next();
});

// Ensure uploads directory exists
const uploadDir = 'uploads';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}

// Multer Storage Configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        cb(null, `${Date.now()}-${file.originalname}`);
    }
});

const upload = multer({ storage });

// Serve Static Files
app.use('/uploads', express.static(uploadDir));

// Health check
app.get('/ping', (req, res) => {
    res.send('pong');
});

// ── API Endpoints ──────────────────────────────────────────

// Get all courses
app.get('/api/courses', async (req, res) => {
    try {
        const courses = await Course.find();
        res.json(courses);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get topics for a course
app.get('/api/topics/:courseId', async (req, res) => {
    try {
        const topics = await Topic.aggregate([
            { $match: { courseId: req.params.courseId } },
            { $sort: { order: 1 } },
            {
                $lookup: {
                    from: 'questions',
                    localField: '_id',
                    foreignField: 'topicId',
                    as: 'questions'
                }
            },
            {
                $addFields: {
                    totalQuestions: { $size: '$questions' }
                }
            },
            {
                $project: {
                    questions: 0
                }
            }
        ]);
        res.json(topics);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get questions for a topic
app.get('/api/questions/:topicId', async (req, res) => {
    try {
        const questions = await Question.find({ topicId: req.params.topicId }).sort({ order: 1 });
        res.json(questions);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create a topic
app.post('/api/topics', async (req, res) => {
    try {
        const topic = new Topic(req.body);
        await topic.save();
        res.status(201).json(topic);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Delete a topic (and its questions)
app.delete('/api/topics/:id', async (req, res) => {
    try {
        const topicId = req.params.id;
        await Topic.findByIdAndDelete(topicId);
        await Question.deleteMany({ topicId: topicId });
        res.json({ message: '✅ Topic and associated questions deleted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Save a question
app.post('/api/questions', async (req, res) => {
    try {
        const question = new Question(req.body);
        await question.save();
        res.status(201).json(question);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Delete a question
app.delete('/api/questions/:id', async (req, res) => {
    try {
        await Question.findByIdAndDelete(req.params.id);
        res.json({ message: '✅ Question deleted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Update a question
app.put('/api/questions/:id', async (req, res) => {
    try {
        const question = await Question.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!question) return res.status(404).json({ error: 'Question not found' });
        res.json(question);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// ── Submission Endpoints ──

// Submit an assignment (text-only)
app.post('/api/submissions', async (req, res) => {
    try {
        const submission = new Submission(req.body);
        await submission.save();
        res.status(201).json(submission);
    } catch (err) {
        console.error('❌ Submission Error:', err);
        res.status(400).json({ error: err.message });
    }
});

// Get submissions for an assignment
app.get('/api/submissions/:assignmentId', async (req, res) => {
    try {
        const submissions = await Submission.find({ assignmentId: req.params.assignmentId }).sort({ submittedAt: -1 });
        res.json(submissions);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Grade a submission
app.patch('/api/submissions/:id', async (req, res) => {
    try {
        const submission = await Submission.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.json(submission);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// ── Assignment Endpoints ──

// Get assignments for a course
app.get('/api/assignments/:courseId', async (req, res) => {
    try {
        const assignments = await Assignment.find({ courseId: req.params.courseId }).sort({ deadline: 1 });
        res.json(assignments);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create an assignment
app.post('/api/assignments', async (req, res) => {
    try {
        const assignment = new Assignment(req.body);
        await assignment.save();
        res.status(201).json(assignment);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Delete an assignment
app.delete('/api/assignments/:id', async (req, res) => {
    try {
        await Assignment.findByIdAndDelete(req.params.id);
        res.json({ message: '✅ Assignment deleted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Seed Initial Data
app.post('/api/seed', async (req, res) => {
    try {
        // Clear existing
        await Course.deleteMany({});
        await Topic.deleteMany({});
        await Question.deleteMany({});
        await Assignment.deleteMany({});
        await Submission.deleteMany({});

        // 1. Mobile App Development
        const madCourse = await Course.create({
            courseId: 'mad',
            title: 'Mobile App Development',
            description: 'Learn to build cross-platform apps with Flutter',
            icon: '📱',
            color: '#3B82F6'
        });

        const madTopics = [
            { id: 'flutter-basics', name: 'Flutter Basics', order: 1 },
            { id: 'state-management', name: 'State Management', order: 2 },
            { id: 'api-integration', name: 'API Integration', order: 3 },
        ];

        for (const t of madTopics) {
            await Topic.create({ _id: t.id, courseId: 'mad', name: t.name, order: t.order });
        }

        // Questions for Flutter Basics
        await Question.create([
            {
                topicId: 'flutter-basics',
                questionText: 'What is a Widget in Flutter?',
                options: ['A UI component', 'A database', 'A network request', 'A hardware sensor'],
                correctOptionIndex: 0,
                explanation: 'Almost everything in Flutter is a widget! They are the basic building blocks of a Flutter app\'s user interface.',
                order: 1
            },
            {
                topicId: 'flutter-basics',
                questionText: 'Which command is used to run a Flutter app?',
                options: ['flutter start', 'flutter run', 'flutter build', 'flutter launch'],
                correctOptionIndex: 1,
                explanation: 'flutter run is the standard command to compile and run your app on a device or emulator.',
                order: 2
            }
        ]);

        // MAD Assignments
        await Assignment.create([
            {
                courseId: 'mad',
                title: 'UI Design Challenge',
                description: 'Create a beautiful login screen using Flutter widgets.',
                deadline: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
                maxScore: 100,
                createdBy: 'instructor'
            },
            {
                courseId: 'mad',
                title: 'Weather API Task',
                description: 'Fetch weather data from an API and display it in a list.',
                deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
                maxScore: 100,
                createdBy: 'instructor'
            }
        ]);

        // Additional Questions for Arrays (DSA)
        await Question.create([
            {
                topicId: 'arrays',
                questionText: 'What is the space complexity of an array of size n?',
                options: ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'],
                correctOptionIndex: 1,
                explanation: 'An array of size n occupies space proportional to n.',
                order: 3
            },
            {
                topicId: 'arrays',
                questionText: 'Given an array of integers `nums` and an integer `target`, return indices of the two numbers such that they add up to `target`.',
                type: 'coding',
                starterCode: 'function twoSum(nums, target) {\n  // Your code here\n}',
                constraints: '2 <= nums.length <= 10^4\n-10^9 <= nums[i] <= 10^9',
                difficulty: 'easy',
                testCases: [
                    { input: '[2,7,11,15], 9', output: '[0,1]', isHidden: false },
                    { input: '[3,2,4], 6', output: '[1,2]', isHidden: false }
                ],
                explanation: 'This is a classic variation of the Two Sum problem using a hash map for O(n) complexity.',
                order: 4
            }
        ]);

        // Questions for Linked Lists
        await Question.create([
            {
                topicId: 'linked-lists',
                questionText: 'What is the time complexity to insert a node at the beginning of a Singly Linked List?',
                options: ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'],
                correctOptionIndex: 0,
                explanation: 'Inserting at the head only requires changing a few pointers, which is O(1).',
                order: 1
            },
            {
                topicId: 'linked-lists',
                questionText: 'In a Doubly Linked List, what does each node contain?',
                options: ['Data and next pointer', 'Data and previous pointer', 'Data, next, and previous pointers', 'Just data'],
                correctOptionIndex: 2,
                explanation: 'Doubly linked lists store pointers to both next and previous nodes.',
                order: 2
            }
        ]);

        // 2. OOP Course
        await Course.create({
            courseId: 'oop',
            title: 'Object Oriented Programming',
            description: 'OOP principles and design patterns',
            icon: '🎯',
            color: '#F59E0B'
        });

        const oopTopics = [
            { id: 'classes-objects', name: 'Classes & Objects', order: 1 },
            { id: 'inheritance', name: 'Inheritance', order: 2 },
            { id: 'polymorphism', name: 'Polymorphism', order: 3 },
        ];

        for (const t of oopTopics) {
            await Topic.create({ _id: t.id, courseId: 'oop', name: t.name, order: t.order });
        }

        await Question.create([
            {
                topicId: 'classes-objects',
                questionText: 'Which of the following is a blueprint for creating objects?',
                options: ['Method', 'Class', 'Variable', 'Interface'],
                correctOptionIndex: 1,
                explanation: 'A class defines the properties and behaviors that objects created from it will have.',
                order: 1
            }
        ]);

        // 3. C Programming Course
        await Course.create({
            courseId: 'c',
            title: 'C Programming',
            description: 'Master the fundamentals of C',
            icon: '⚡',
            color: '#3B82F6'
        });

        await Topic.create({ _id: 'c-basics', courseId: 'c', name: 'Basics & Syntax', order: 1 });
        await Question.create([
            {
                topicId: 'c-basics',
                questionText: 'Which function is used to print text in C?',
                options: ['print()', 'echo()', 'printf()', 'System.out.println()'],
                correctOptionIndex: 2,
                explanation: 'printf() is the standard output function in C.',
                order: 1
            }
        ]);

        res.json({ message: '✅ Database seeded successfully with multi-course data!' });
    } catch (err) {
        console.error('❌ Seeding Error:', err);
        res.status(500).json({ error: err.message });
    }
});

// ── Gemini Chatbot Endpoint ──────────────────────────────

app.post('/api/chatbot', async (req, res) => {
    const { contents } = req.body;

    if (!contents || !Array.isArray(contents)) {
        return res.status(400).json({ error: 'Invalid contents format' });
    }

    try {
        console.log(`🤖 Gemini Request: ${contents.length} messages`);

        const result = await model.generateContent({
            contents: contents,
        });

        const response = await result.response;
        const text = response.text();

        res.json({
            candidates: [
                {
                    content: {
                        parts: [
                            { text: text }
                        ]
                    }
                }
            ]
        });
    } catch (err) {
        console.error('❌ Gemini API Error:', err);
        res.status(500).json({
            error: {
                message: err.message || 'Error generating content from Gemini'
            }
        });
    }
});

// ── Server Setup ──────────────────────────────────────────

const startServer = async () => {
    try {
        console.log('🔄 Connecting to MongoDB with URI:', process.env.MONGODB_URI);
        await mongoose.connect(process.env.MONGODB_URI, {
            serverSelectionTimeoutMS: 30000,
            connectTimeoutMS: 30000
        });
        console.log('✅ Connected to MongoDB Atlas');

        const server = app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
        });

        server.on('error', (err) => {
            if (err.code === 'EADDRINUSE') {
                console.error(`❌ Port ${PORT} is already in use by another application.`);
                console.error(`⚠️  Please change the PORT in backend/.env to another number (e.g., 6000, 6001).`);
                process.exit(1);
            } else {
                console.error('❌ Server Error:', err);
            }
        });
    } catch (err) {
        console.error('❌ MongoDB Connection Error:', err.message);
        console.error('⚠️  Please update MONGODB_URI in backend/.env');
        // Do not exit, just wait or allow retry if using nodemon
    }
};

startServer();
