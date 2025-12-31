import 'package:fluency/features/course/domain/entities/course.dart';

class FakeCourseData {
  static const Course hackerToeicListening = Course(
    id: 'course_001',
    title: 'Hacker TOEIC Start Listening',
    imageUrl:
        'https://bizweb.dktcdn.net/100/180/408/products/hacker-toeic-start-listening-43ca5917-9ea4-47e7-a463-e8ce824ad6e0.jpg',
    author: 'David Cho',
    translator: 'Alphabooks',
    adapter: 'KhanhRomVN',
    pageCount: 576,
    publisher: 'NXB Dân Trí',
    publicationYear: 2020,
    skill: ['Listening'],
    shortDescription:
        'The ultimate guide to mastering TOEIC Listening for beginners.',
    fullDescription:
        'This course is designed for those starting their TOEIC journey. '
        'It covers all fundamental listening concepts, provides extensive practice '
        'exercises, and includes detailed explanations in Vietnamese to help you '
        'understand even the trickiest parts. '
        'Optimized for mobile learning with interactive lessons.',
    targetAudience: 'Vietnamese',
    lessons: [
      Lesson(
        id: 'l_01',
        title: 'Part 1: Photographs',
        lessonNumber: 1,
        quizCount: 10,
      ),
      Lesson(
        id: 'l_02',
        title: 'Part 2: Question-Response',
        lessonNumber: 2,
        quizCount: 25,
      ),
      Lesson(
        id: 'l_03',
        title: 'Part 3: Conversations',
        lessonNumber: 3,
        quizCount: 30,
      ),
      Lesson(
        id: 'l_04',
        title: 'Part 4: Talks',
        lessonNumber: 4,
        quizCount: 20,
      ),
      Lesson(
        id: 'l_05',
        title: 'Practice Test 1',
        lessonNumber: 5,
        quizCount: 100,
      ),
      Lesson(
        id: 'l_06',
        title: 'Practice Test 2',
        lessonNumber: 6,
        quizCount: 100,
      ),
    ],
    completedLessons: 4,
  );

  static const Course hackerToeicReading = Course(
    id: 'course_002',
    title: 'Hacker TOEIC Start Reading',
    imageUrl:
        'https://bizweb.dktcdn.net/100/180/408/products/hacker-toeic-start-reading-5c1892e0-398c-4e31-becf-1f9e74e874b9.jpg',
    author: 'David Cho',
    translator: 'Alphabooks',
    adapter: 'KhanhRomVN',
    pageCount: 500,
    publisher: 'NXB Dân Trí',
    publicationYear: 2020,
    skill: ['Reading'],
    shortDescription: 'Master TOEIC Reading fundamentals with ease.',
    fullDescription: 'Comprehensive reading practice for TOEIC beginners.',
    targetAudience: 'Vietnamese',
    lessons: [
      Lesson(
        id: 'l_rw_01',
        title: 'Part 5: Incomplete Sentences',
        lessonNumber: 1,
        quizCount: 30,
      ),
      Lesson(
        id: 'l_rw_02',
        title: 'Part 6: Text Completion',
        lessonNumber: 2,
        quizCount: 16,
      ),
      Lesson(
        id: 'l_rw_03',
        title: 'Part 7: Reading Comprehension',
        lessonNumber: 3,
        quizCount: 40,
      ),
      Lesson(
        id: 'l_rw_04',
        title: 'Practice Test',
        lessonNumber: 4,
        quizCount: 100,
      ),
    ],
    completedLessons: 1,
  );

  static const Course oxfordReadingWriting = Course(
    id: 'course_003',
    title: 'Oxford English Practice Series - Reading & Writing 1',
    imageUrl:
        'https://shop.oupchina.com.hk/cdn/shop/products/oxford-english-practice-series-reading-writing-xiao-xue-bu-chong-lian-xi-oupshop-xiao-577913.png?v=1635239829&width=1200',
    author: 'Oxford',
    translator: 'Oxford',
    adapter: 'KhanhRomVN',
    pageCount: 150,
    publisher: 'Oxford University Press',
    publicationYear: 2021,
    skill: ['Reading', 'Writing'],
    shortDescription: 'Essential reading and writing practice.',
    fullDescription:
        'Develop key reading and writing skills with engaging exercises.',
    targetAudience: 'Global',
    lessons: [
      Lesson(
        id: 'l_ox_01',
        title: 'Unit 1: Family',
        lessonNumber: 1,
        quizCount: 15,
      ),
      Lesson(
        id: 'l_ox_02',
        title: 'Unit 2: School',
        lessonNumber: 2,
        quizCount: 15,
      ),
      Lesson(
        id: 'l_ox_03',
        title: 'Unit 3: Hobbies',
        lessonNumber: 3,
        quizCount: 15,
      ),
      Lesson(
        id: 'l_ox_04',
        title: 'Review 1',
        lessonNumber: 4,
        quizCount: 30,
      ),
    ],
    completedLessons: 0,
  );

  static const Course cambridgeIelts18 = Course(
    id: 'course_004',
    title: 'Cambridge IELTS 18',
    imageUrl: 'https://i.ibb.co/G3fY83zT/English-IELTS-18-231x300.jpg',
    author: 'Cambridge University Press',
    translator: '',
    adapter: 'KhanhRomVN',
    pageCount: 144,
    publisher: 'Cambridge University Press',
    publicationYear: 2023,
    skill: ['Listening', 'Reading', 'Writing', 'Speaking'],
    shortDescription: 'The latest official Cambridge IELTS practice tests.',
    fullDescription:
        'Authentic examination papers from Cambridge Assessment English provide perfect practice because they are EXACTLY like the real test. '
        'Inside IELTS 18 with Answers with Audio you will find FOUR complete examination papers plus details of the different parts of the test and the scoring system, so you can familiarise yourself with the test format and practise your exam technique.',
    targetAudience: 'Global',
    lessons: [],
    completedLessons: 0,
  );

  static const List<Course> courses = [
    hackerToeicListening,
    hackerToeicReading,
    oxfordReadingWriting,
    cambridgeIelts18,
  ];
}
