<?php

namespace Database\Seeders;

use App\Models\Badge;
use App\Models\ChallengeCategory;
use App\Models\ChallengeTemplate;
use App\Models\KnowledgeArticle;
use App\Services\Ai\KnowledgeChunker;
use Illuminate\Database\Seeder;

/**
 * Demo content shared across the hackathon backend team.
 *
 * Idempotent by design (firstOrCreate/updateOrCreate) so re-running
 * `php artisan db:seed` never duplicates rows — multiple devs/issues may
 * extend this seeder, so keep additions additive and idempotent.
 */
class DemoSeeder extends Seeder
{
    /**
     * Seed challenge categories + starter templates
     * (docs/mvp/issues/03-categories-templates-api.md).
     */
    public function run(): void
    {
        $categories = [
            ['name' => 'Health', 'slug' => 'health'],
            ['name' => 'Focus', 'slug' => 'focus'],
            ['name' => 'Wellbeing', 'slug' => 'wellbeing'],
        ];

        $categoriesBySlug = [];

        foreach ($categories as $category) {
            $categoriesBySlug[$category['slug']] = ChallengeCategory::firstOrCreate(
                ['slug' => $category['slug']],
                ['name' => $category['name']]
            );
        }

        $templates = [
            [
                'title' => '7-Day Morning Walk',
                'description' => 'Walk 10 minutes each morning',
                'difficulty' => 'beginner',
                'duration_days' => 7,
                'category' => 'health',
            ],
            [
                'title' => 'No Sugar Week',
                'description' => 'Cut added sugar for 7 days',
                'difficulty' => 'medium',
                'duration_days' => 7,
                'category' => 'health',
            ],
            [
                'title' => 'Night Phone Curfew',
                'description' => 'No phone 30 minutes before bed',
                'difficulty' => 'easy',
                'duration_days' => 7,
                'category' => 'focus',
            ],
        ];

        foreach ($templates as $template) {
            ChallengeTemplate::firstOrCreate(
                ['title' => $template['title']],
                [
                    'description' => $template['description'],
                    'difficulty' => $template['difficulty'],
                    'duration_days' => $template['duration_days'],
                    'category_id' => $categoriesBySlug[$template['category']]->id,
                ]
            );
        }

        $this->seedBadges();
        $this->seedKnowledgeArticles();
    }

    /**
     * Seed the 3 MVP gamification badges (docs/mvp/issues/06-gamification-admin.md
     * "Badge auto-unlock"). Codes must match App\Services\BadgeService's
     * constants exactly.
     */
    private function seedBadges(): void
    {
        $badges = [
            [
                'code' => 'first_checkin',
                'name' => 'First Step',
                'description' => 'Completed your first check-in',
            ],
            [
                'code' => 'streak_3',
                'name' => 'On a Roll',
                'description' => 'Reached a 3-day streak on a challenge',
            ],
            [
                'code' => 'comeback',
                'name' => 'The Comeback',
                'description' => 'Bounced back with a completed check-in right after a missed one',
            ],
        ];

        foreach ($badges as $badge) {
            Badge::firstOrCreate(
                ['code' => $badge['code']],
                [
                    'name' => $badge['name'],
                    'description' => $badge['description'],
                ]
            );
        }
    }

    /**
     * Seed the 5 MVP knowledge articles for the RAG chatbot
     * (docs/mvp/issues/08-ai-rag-chat.md "Seed knowledge"). Each body is
     * multi-paragraph so KnowledgeChunker produces several chunks per
     * article. Chunking is explicitly re-triggered here (rather than
     * relying solely on the model's `saved` event) so chunks are
     * guaranteed to exist even if an article already existed from a
     * previous run.
     */
    private function seedKnowledgeArticles(): void
    {
        $articles = [
            [
                'title' => 'Tiny habits starter',
                'category' => 'habits',
                'body' => "Start absurdly small; consistency beats intensity. If a habit takes less than two minutes, "
                    ."there's almost no excuse to skip it, and showing up every day matters far more than how much you "
                    ."do on any single day.\n\n"
                    ."Anchor the new habit to something you already do without thinking, like brushing your teeth or "
                    ."making coffee. That existing routine becomes the trigger, so you don't have to rely on willpower "
                    ."or memory to remember to start.\n\n"
                    ."Once the tiny version feels automatic — usually after a couple of weeks — you can grow it "
                    ."naturally. Trying to go big on day one is the most common reason people quit; going small is "
                    ."the most reliable way to still be doing it a month from now.",
            ],
            [
                'title' => 'Recovery basics',
                'category' => 'recovery',
                'body' => "After a miss, restart with a tiny action instead of quitting; one miss is not a failure. "
                    ."Everybody misses a day sooner or later — what separates people who succeed long-term isn't a "
                    ."perfect record, it's how quickly they get back on track.\n\n"
                    ."The best way to recover is to make the very next check-in easier than usual, not harder. If "
                    ."your challenge is a 20-minute workout, come back with 5 minutes. The goal of a comeback day is "
                    ."to prove to yourself that you're still in the game, not to make up for lost time.\n\n"
                    ."Avoid the trap of 'all or nothing' thinking, where a single skipped day turns into a skipped "
                    ."week. Treat the miss as data, not a verdict on your character, and move on to the next check-in "
                    ."as soon as you can.",
            ],
            [
                'title' => 'Humane streaks',
                'category' => 'streaks',
                'body' => "Streaks are a tool for motivation, not a measure of self-worth; a broken streak doesn't "
                    ."erase progress. A long streak can feel great, but it can also create pressure that makes people "
                    ."quit entirely the moment they miss a single day, which defeats the whole purpose.\n\n"
                    ."It helps to reframe a streak as 'days practiced' rather than 'days without failure'. Under that "
                    ."framing, missing a day doesn't reset your identity as someone who shows up — it's just one data "
                    ."point in a much longer story.\n\n"
                    ."If you find yourself dreading a check-in because you're scared of losing a streak, that's a "
                    ."signal to lower the difficulty, not to give up. The habit should serve you, not the other way "
                    ."around.",
            ],
            [
                'title' => 'How check-ins work',
                'category' => 'faq',
                'body' => "A check-in records a completed or skipped day for a challenge; each challenge allows one "
                    ."check-in per calendar day. You can mark a day as completed, skipped, or missed, and that status "
                    ."feeds directly into your streak, XP, and progress percentage for that challenge.\n\n"
                    ."Check-ins use your profile's timezone to determine what counts as 'today', so the day boundary "
                    ."lines up with your actual schedule rather than server time. If you already checked in today for "
                    ."a challenge, the app will tell you rather than letting you submit a duplicate.",
            ],
            [
                'title' => 'Writing a good challenge',
                'category' => 'faq',
                'body' => "Good challenges are specific, small, and tied to a clear trigger or time of day. "
                    ."'Walk 10 minutes after breakfast' works better than 'exercise more' because it's unambiguous — "
                    ."you'll always know whether you did it or not.\n\n"
                    ."Pick a duration you can realistically sustain, usually somewhere between one and four weeks for "
                    ."a first attempt. Shorter challenges are easier to finish and build confidence for tackling "
                    ."bigger ones later.\n\n"
                    ."Finally, choose a difficulty that's honest about your current capacity rather than aspirational. "
                    ."It's far better to complete an 'easy' challenge consistently than to abandon a 'hard' one after "
                    ."three days.",
            ],
        ];

        foreach ($articles as $data) {
            $article = KnowledgeArticle::firstOrCreate(
                ['title' => $data['title']],
                [
                    'category' => $data['category'],
                    'body' => $data['body'],
                    'is_active' => true,
                ]
            );

            app(KnowledgeChunker::class)->chunk($article);
        }
    }
}
