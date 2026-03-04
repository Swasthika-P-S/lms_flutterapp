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

// Ensure uploads directory exists (use /tmp for serverless if needed)
const uploadDir = process.env.VERCEL ? '/tmp' : 'uploads';
try {
    if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
    }
} catch (err) {
    console.warn('⚠️ Could not create upload directory:', err.message);
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

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'UP',
        env: process.env.NODE_ENV,
        dbStatus: mongoose.connection.readyState,
        hasUri: !!process.env.MONGODB_URI,
        timestamp: new Date().toISOString()
    });
});

// ── Course Endpoints ──────────────────────────────────────────

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

        // ─── 1. DSA Course ───────────────────────────────────────────
        await Course.create({
            courseId: 'dsa',
            title: 'Data Structures & Algorithms',
            description: 'Master arrays, linked lists, trees, graphs and more',
            icon: '🌳',
            color: '#6C63FF'
        });

        const dsaTopics = [
            { id: 'arrays', name: 'Arrays', order: 1 },
            { id: 'linked-lists', name: 'Linked Lists', order: 2 },
            { id: 'trees', name: 'Trees', order: 3 },
        ];
        for (const t of dsaTopics) {
            await Topic.create({ _id: t.id, courseId: 'dsa', name: t.name, order: t.order });
        }

        // Arrays questions
        await Question.create([
            {
                topicId: 'arrays', type: 'quiz',
                questionText: 'What is the time complexity of accessing an element in an array by index?',
                options: ['O(n)', 'O(log n)', 'O(1)', 'O(n²)'],
                correctOptionIndex: 2,
                explanation: 'Arrays allow direct index-based access in constant time O(1) since elements are stored contiguously in memory.',
                order: 1
            },
            {
                topicId: 'arrays', type: 'quiz',
                questionText: 'Which operation is most expensive for a dynamic array when it needs to grow?',
                options: ['Accessing an element', 'Resizing (copying all elements)', 'Appending to an empty slot', 'Reading the length'],
                correctOptionIndex: 1,
                explanation: 'When a dynamic array runs out of capacity, it must allocate a new larger array and copy all existing elements, which is O(n).',
                order: 2
            },
            {
                topicId: 'arrays', type: 'quiz',
                questionText: 'What is the space complexity of an array of size n?',
                options: ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'],
                correctOptionIndex: 1,
                explanation: 'An array of size n stores n elements, so it occupies O(n) space.',
                order: 3
            },
            {
                topicId: 'arrays', type: 'quiz',
                questionText: 'In a sorted array, which algorithm is most efficient for searching?',
                options: ['Linear Search', 'Jump Search', 'Binary Search', 'Bubble Sort'],
                correctOptionIndex: 2,
                explanation: 'Binary Search repeatedly halves the search space, achieving O(log n) time in a sorted array.',
                order: 4
            }
        ]);

        // Linked Lists questions
        await Question.create([
            {
                topicId: 'linked-lists', type: 'quiz',
                questionText: 'What is the time complexity to insert a node at the beginning of a Singly Linked List?',
                options: ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'],
                correctOptionIndex: 0,
                explanation: 'Inserting at the head only requires updating the head pointer and the new node\'s next pointer — no traversal needed, so it\'s O(1).',
                order: 1
            },
            {
                topicId: 'linked-lists', type: 'quiz',
                questionText: 'In a Doubly Linked List, each node contains:',
                options: ['Data and next pointer only', 'Data and previous pointer only', 'Data, next, and previous pointers', 'Only data'],
                correctOptionIndex: 2,
                explanation: 'Doubly linked list nodes hold data plus pointers to both the next and previous nodes.',
                order: 2
            },
            {
                topicId: 'linked-lists', type: 'quiz',
                questionText: 'Which linked list variant allows the last node to point back to the head?',
                options: ['Doubly Linked List', 'Circular Linked List', 'Skip List', 'XOR Linked List'],
                correctOptionIndex: 1,
                explanation: 'A Circular Linked List has its last node\'s next pointer pointing back to the head, forming a cycle.',
                order: 3
            },
            {
                topicId: 'linked-lists', type: 'quiz',
                questionText: 'What is the time complexity of searching for a value in an unsorted singly linked list?',
                options: ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
                correctOptionIndex: 2,
                explanation: 'In the worst case, you must traverse every node to find the target value, which is O(n).',
                order: 4
            }
        ]);

        // Trees questions
        await Question.create([
            {
                topicId: 'trees', type: 'quiz',
                questionText: 'In a Binary Search Tree (BST), where are smaller values stored relative to the root?',
                options: ['Right subtree', 'Left subtree', 'Randomly', 'At the root'],
                correctOptionIndex: 1,
                explanation: 'BST property: all values in the left subtree are less than the root, and all values in the right subtree are greater.',
                order: 1
            },
            {
                topicId: 'trees', type: 'quiz',
                questionText: 'Which tree traversal visits nodes in Left → Root → Right order?',
                options: ['Pre-order', 'Post-order', 'In-order', 'Level-order'],
                correctOptionIndex: 2,
                explanation: 'In-order traversal (Left → Root → Right) visits nodes in sorted order for a BST.',
                order: 2
            },
            {
                topicId: 'trees', type: 'quiz',
                questionText: 'What is the height of a balanced binary tree with n nodes?',
                options: ['O(n)', 'O(n²)', 'O(log n)', 'O(1)'],
                correctOptionIndex: 2,
                explanation: 'A balanced binary tree distributes nodes evenly, so its height is O(log n).',
                order: 3
            },
            {
                topicId: 'trees', type: 'quiz',
                questionText: 'A node with no children in a tree is called:',
                options: ['Root', 'Parent', 'Leaf', 'Branch'],
                correctOptionIndex: 2,
                explanation: 'A leaf node (or external node) has no children. The root is the topmost node.',
                order: 4
            },
            {
                topicId: 'arrays', type: 'coding',
                questionText: 'Given an empty function `getArray()`, write code to return an array containing the numbers 1, 2, and 3.',
                starterCode: 'function getArray() {\n  // Your code here\n}',
                constraints: 'Return exactly [1, 2, 3]',
                testCases: [
                    { input: 'getArray()', output: '[1,2,3]' }
                ],
                explanation: 'In JavaScript, you can create and return an array using square brackets: return [1, 2, 3];',
                order: 3
            },
            {
                topicId: 'arrays', type: 'coding',
                questionText: 'Array Sum\nWrite a function that returns the sum of all elements in the given array `arr`.',
                starterCode: 'function sumArray(arr) {\n  let sum = 0;\n  // Your code here\n  \n  return sum;\n}',
                constraints: 'The array will contain at least 1 element.',
                testCases: [
                    { input: '[1, 2, 3]', output: '6' },
                    { input: '[10, -2, 5]', output: '13' }
                ],
                explanation: 'A simple for loop can iterate through the array and add each element to the `sum` variable.',
                order: 4
            }
        ]);

        // DSA Assignments
        await Assignment.create([
            {
                courseId: 'dsa',
                title: 'Array Manipulation',
                description: 'Implement a function to find the maximum subarray sum using Kadane\'s algorithm.',
                deadline: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
                maxScore: 100,
                createdBy: 'instructor'
            },
            {
                courseId: 'dsa',
                title: 'Linked List Reversal',
                description: 'Write a program to reverse a singly linked list both iteratively and recursively.',
                deadline: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
                maxScore: 100,
                createdBy: 'instructor'
            }
        ]);

        // ─── 2. OOP Course ───────────────────────────────────────────
        await Course.create({
            courseId: 'oop',
            title: 'Object Oriented Programming',
            description: 'Master OOP principles: encapsulation, inheritance, polymorphism & abstraction',
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
                topicId: 'classes-objects', type: 'quiz',
                questionText: 'Which of the following is a blueprint for creating objects?',
                options: ['Method', 'Class', 'Variable', 'Interface'],
                correctOptionIndex: 1,
                explanation: 'A class defines the attributes and behaviors that its objects will have.',
                order: 1
            },
            {
                topicId: 'classes-objects', type: 'quiz',
                questionText: 'What is encapsulation in OOP?',
                options: ['Hiding implementation details within a class', 'Creating multiple classes', 'Inheriting from a parent class', 'Using the same method name with different parameters'],
                correctOptionIndex: 0,
                explanation: 'Encapsulation bundles data and methods together and restricts direct access to internal state.',
                order: 2
            },
            {
                topicId: 'inheritance', type: 'quiz',
                questionText: 'Which keyword is used to inherit a class in Java?',
                options: ['implements', 'extends', 'inherits', 'super'],
                correctOptionIndex: 1,
                explanation: 'In Java, the "extends" keyword allows a child class to inherit from a parent class.',
                order: 1
            },
            {
                topicId: 'inheritance', type: 'quiz',
                questionText: 'What is the type of inheritance where a class inherits from more than one class?',
                options: ['Single', 'Multilevel', 'Hierarchical', 'Multiple'],
                correctOptionIndex: 3,
                explanation: 'Multiple inheritance allows a class to inherit from more than one parent class (supported in C++, not directly in Java).',
                order: 2
            },
            {
                topicId: 'polymorphism', type: 'quiz',
                questionText: 'Method overriding is an example of:',
                options: ['Compile-time polymorphism', 'Runtime polymorphism', 'Encapsulation', 'Abstraction'],
                correctOptionIndex: 1,
                explanation: 'Method overriding is resolved at runtime based on the actual object type — this is runtime (dynamic) polymorphism.',
                order: 1
            },
            {
                topicId: 'polymorphism', type: 'quiz',
                questionText: 'Method overloading is also known as:',
                options: ['Runtime polymorphism', 'Dynamic binding', 'Compile-time polymorphism', 'Late binding'],
                correctOptionIndex: 2,
                explanation: 'Method overloading is resolved at compile time based on the method signature — this is compile-time (static) polymorphism.',
                order: 2
            },
            {
                topicId: 'classes-objects', type: 'coding',
                questionText: 'Design a simple Class\nCreate a class named "Car" with a method "startEngine" that returns the string "Engine started".',
                starterCode: 'class Car {\n  // Define startEngine method here\n}',
                constraints: 'Method name must be exactly "startEngine"',
                testCases: [
                    { input: 'const myCar = new Car(); myCar.startEngine()', output: '"Engine started"' }
                ],
                explanation: 'Classes encapsulate data and behavior. The class keyword is used to define a class with its methods.',
                order: 3
            }
        ]);

        await Assignment.create([
            {
                courseId: 'oop',
                title: 'Design a Bank Account Class',
                description: 'Create a BankAccount class with deposit, withdraw, and balance methods. Implement encapsulation properly.',
                deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
                maxScore: 100,
                createdBy: 'instructor'
            }
        ]);

        // ─── 3. C Programming Course ─────────────────────────────────
        await Course.create({
            courseId: 'c',
            title: 'C Programming',
            description: 'Master the fundamentals of C: pointers, memory, and file I/O',
            icon: '⚡',
            color: '#3B82F6'
        });

        const cTopics = [
            { id: 'c-basics', name: 'Basics & Syntax', order: 1 },
            { id: 'c-pointers', name: 'Pointers & Memory', order: 2 },
            { id: 'c-functions', name: 'Functions', order: 3 },
        ];
        for (const t of cTopics) {
            await Topic.create({ _id: t.id, courseId: 'c', name: t.name, order: t.order });
        }

        await Question.create([
            {
                topicId: 'c-basics', type: 'quiz',
                questionText: 'Which function is used to print text in C?',
                options: ['print()', 'echo()', 'printf()', 'System.out.println()'],
                correctOptionIndex: 2,
                explanation: 'printf() is the standard output function in C, defined in <stdio.h>.',
                order: 1
            },
            {
                topicId: 'c-basics', type: 'quiz',
                questionText: 'What is the correct way to declare an integer variable in C?',
                options: ['integer x;', 'int x;', 'var x;', 'x = int;'],
                correctOptionIndex: 1,
                explanation: 'In C, "int" is the keyword for declaring integer variables.',
                order: 2
            },
            {
                topicId: 'c-basics', type: 'quiz',
                questionText: 'Which of these is the entry point of a C program?',
                options: ['start()', 'begin()', 'main()', 'run()'],
                correctOptionIndex: 2,
                explanation: 'Every C program must have a main() function — it is where program execution begins.',
                order: 3
            },
            {
                topicId: 'c-pointers', type: 'quiz',
                questionText: 'What does the & operator do in C?',
                options: ['Dereferences a pointer', 'Returns the address of a variable', 'Performs bitwise AND', 'Declares a reference'],
                correctOptionIndex: 1,
                explanation: '& is the address-of operator. &x gives the memory address of variable x.',
                order: 1
            },
            {
                topicId: 'c-pointers', type: 'quiz',
                questionText: 'What does the * operator do when used with a pointer variable?',
                options: ['Gets the address', 'Multiplies values', 'Dereferences — accesses value at that address', 'Declares a new pointer'],
                correctOptionIndex: 2,
                explanation: 'The * operator dereferences a pointer, giving access to the value stored at the address the pointer holds.',
                order: 2
            },
            {
                topicId: 'c-functions', type: 'quiz',
                questionText: 'What is a function prototype in C?',
                options: ['The function\'s return value', 'A declaration of the function before its definition', 'The function body', 'A global variable'],
                correctOptionIndex: 1,
                explanation: 'A function prototype tells the compiler the function\'s name, return type, and parameters before the actual definition.',
                order: 1
            },
            {
                topicId: 'c-functions', type: 'quiz',
                questionText: 'Which storage class makes a variable retain its value between function calls?',
                options: ['auto', 'extern', 'static', 'register'],
                correctOptionIndex: 2,
                explanation: 'A "static" local variable retains its value across multiple calls to the function.',
                order: 2
            },
            {
                topicId: 'c-pointers', type: 'coding',
                questionText: 'Pointer Swap\nWrite a function swap(int *a, int *b) that swaps the values of two integers using pointers.',
                starterCode: 'void swap(int *a, int *b) {\n  // Your code here\n}',
                constraints: 'Do not use any global variables.',
                testCases: [
                    { input: 'int x = 5, y = 10; swap(&x, &y); printf("%d %d", x, y);', output: '10 5' }
                ],
                explanation: 'You need to dereference the pointers using the * operator to access and swap the actual values stored at those memory addresses.',
                order: 3
            }
        ]);

        await Assignment.create([
            {
                courseId: 'c',
                title: 'Pointer Arithmetic',
                description: 'Write a C program that demonstrates pointer arithmetic by traversing an array using pointers.',
                deadline: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000),
                maxScore: 100,
                createdBy: 'instructor'
            }
        ]);

        res.json({ message: '✅ Database seeded with DSA, OOP, and C Programming courses!' });
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

// Cached connection variable
let isConnected = false;

const connectDB = async () => {
    if (isConnected && mongoose.connection.readyState === 1) {
        return;
    }

    try {
        console.log('🔄 Connecting to MongoDB...');
        const db = await mongoose.connect(process.env.MONGODB_URI, {
            serverSelectionTimeoutMS: 5000, // Reduced for faster serverless response
            connectTimeoutMS: 10000,
        });
        isConnected = db.connections[0].readyState === 1;
        console.log('✅ Connected to MongoDB Atlas');
    } catch (err) {
        console.error('❌ MongoDB Connection Error:', err.message);
        throw err;
    }
};

// Middleware to ensure DB is connected before any request
app.use(async (req, res, next) => {
    try {
        await connectDB();
        next();
    } catch (err) {
        res.status(500).json({ error: 'Database connection failed' });
    }
});

// Start the server locally if not on Vercel
if (process.env.NODE_ENV !== 'production' && !process.env.VERCEL) {
    connectDB().then(() => {
        const server = app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
        });

        server.on('error', (err) => {
            if (err.code === 'EADDRINUSE') {
                console.error(`❌ Port ${PORT} is already in use.`);
                process.exit(1);
            } else {
                console.error('❌ Server Error:', err);
            }
        });
    });
}

module.exports = app;
