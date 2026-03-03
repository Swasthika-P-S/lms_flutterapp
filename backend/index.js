require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const Course = require('./models/Course');
const Topic = require('./models/Topic');
const Question = require('./models/Question');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

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
        res.json(question);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// Seed Initial Data
app.post('/api/seed', async (req, res) => {
    try {
        // Clear existing
        await Course.deleteMany({});
        await Topic.deleteMany({});
        await Question.deleteMany({});

        // 1. DSA Course
        const dsaCourse = await Course.create({
            courseId: 'dsa',
            title: 'Data Structures & Algorithms',
            description: 'Master DSA for technical interviews',
            icon: '🌳',
            color: '#8B5CF6'
        });

        const dsaTopics = [
            { id: 'arrays', name: 'Arrays', order: 1 },
            { id: 'linked-lists', name: 'Linked Lists', order: 2 },
            { id: 'stacks-queues', name: 'Stacks & Queues', order: 3 },
            { id: 'trees', name: 'Trees', order: 4 },
        ];

        for (const t of dsaTopics) {
            await Topic.create({ _id: t.id, courseId: 'dsa', name: t.name, order: t.order });
        }

        // Questions for Arrays
        await Question.create([
            {
                topicId: 'arrays',
                questionText: 'What is the time complexity of accessing an array element by index?',
                options: ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'],
                correctOptionIndex: 0,
                explanation: 'Array access by index is O(1) — the memory address is computed directly.',
                order: 1
            },
            {
                topicId: 'arrays',
                questionText: 'Which describes a Dynamic Array?',
                options: ['Fixed size at compile time', 'Can grow/shrink at runtime', 'Stores integers only', 'Non-contiguous memory'],
                correctOptionIndex: 1,
                explanation: 'Dynamic arrays (e.g. vector in C++) resize themselves as needed.',
                order: 2
            },
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

// ── Server Setup ──────────────────────────────────────────

const startServer = async () => {
    try {
        console.log('🔄 Connecting to MongoDB with URI:', process.env.MONGODB_URI);
        await mongoose.connect(process.env.MONGODB_URI, {
            serverSelectionTimeoutMS: 30000,
            connectTimeoutMS: 30000
        });
        console.log('✅ Connected to MongoDB Atlas');

        app.listen(PORT, () => {
            console.log(`🚀 Server running on http://localhost:${PORT}`);
        });
    } catch (err) {
        console.error('❌ MongoDB Connection Error:', err.message);
        console.error('⚠️  Please update MONGODB_URI in backend/.env');
        // Do not exit, just wait or allow retry if using nodemon
    }
};

startServer();
