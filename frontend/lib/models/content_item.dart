/// Content type enum for articles, videos, and courses
enum ContentType { article, video, course }

/// Model representing a piece of educational content (article, video, or course).
/// Titles and descriptions are pre-populated; URLs are left null until the user
/// provides real links.
class ContentItem {
  final String id;
  final String title;
  final String description;
  final String duration; // e.g. "5 min read", "10 min"
  final ContentType type;
  final String? imageUrl;
  final String? articleUrl;
  final String? videoUrl;
  final String category; // e.g. "Anxiety", "Mindfulness", "CBT"

  const ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.type,
    this.imageUrl,
    this.articleUrl,
    this.videoUrl,
    this.category = 'General',
  });

  /// Placeholder articles – titles & descriptions ready; URLs to be injected later
  static const List<ContentItem> sampleArticles = [
    ContentItem(
      id: 'art_1',
      title: 'Understanding Anxiety',
      description: 'Learn about the causes, symptoms, and management strategies for anxiety disorders.',
      duration: '5 min read',
      type: ContentType.article,
      category: 'Anxiety',
      articleUrl: 'https://www.nimh.nih.gov/health/topics/anxiety-disorders',
    ),
    ContentItem(
      id: 'art_2',
      title: 'Stress Management Techniques',
      description: 'Practical strategies for managing daily stress and building resilience.',
      duration: '8 min read',
      type: ContentType.article,
      category: 'Stress',
      articleUrl: 'https://www.apa.org/topics/stress/tips',
    ),
    ContentItem(
      id: 'art_3',
      title: 'The Science of Sleep',
      description: 'How sleep affects your mental health and tips for better rest.',
      duration: '6 min read',
      type: ContentType.article,
      category: 'Sleep',
      articleUrl: 'https://www.sleepfoundation.org/mental-health',
    ),
    ContentItem(
      id: 'art_4',
      title: 'Building Healthy Habits',
      description: 'A step-by-step guide to establishing routines that support mental wellness.',
      duration: '7 min read',
      type: ContentType.article,
      category: 'Wellness',
      articleUrl: 'https://www.health.harvard.edu/healthbeat/how-to-break-a-bad-habit',
    ),
  ];

  /// Placeholder videos – titles & descriptions ready; URLs to be injected later
  static const List<ContentItem> sampleVideos = [
    ContentItem(
      id: 'vid_1',
      title: 'Introduction to Mindfulness',
      description: 'A beginner-friendly guide to mindfulness meditation and present-moment awareness.',
      duration: '12 min',
      type: ContentType.video,
      category: 'Mindfulness',
      videoUrl: 'https://www.youtube.com/watch?v=ZToicYcHIOU',
    ),
    ContentItem(
      id: 'vid_2',
      title: 'CBT Basics',
      description: 'Understanding Cognitive Behavioral Therapy and how it can help manage thoughts.',
      duration: '15 min',
      type: ContentType.video,
      category: 'CBT',
      videoUrl: 'https://www.youtube.com/watch?v=9c_Bv_FBE-c',
    ),
    ContentItem(
      id: 'vid_3',
      title: 'Breathing for Calm',
      description: 'Guided breathing exercises you can do anywhere to reduce anxiety instantly.',
      duration: '8 min',
      type: ContentType.video,
      category: 'Breathing',
      videoUrl: 'https://www.youtube.com/watch?v=acUZdGd_3Oo',
    ),
    ContentItem(
      id: 'vid_4',
      title: 'Understanding ADHD',
      description: 'Learn about ADHD symptoms, diagnosis, and evidence-based treatment options.',
      duration: '18 min',
      type: ContentType.video,
      category: 'ADHD',
      videoUrl: 'https://www.youtube.com/watch?v=jhcn1_qsYmg',
    ),
  ];
}
