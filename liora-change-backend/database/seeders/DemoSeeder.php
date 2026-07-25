<?php

namespace Database\Seeders;

use App\Models\Badge;
use App\Models\ChallengeCategory;
use App\Models\ChallengeTemplate;
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
}
