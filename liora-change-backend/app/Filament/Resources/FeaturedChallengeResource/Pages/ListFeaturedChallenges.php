<?php

namespace App\Filament\Resources\FeaturedChallengeResource\Pages;

use App\Filament\Resources\FeaturedChallengeResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListFeaturedChallenges extends ListRecords
{
    protected static string $resource = FeaturedChallengeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
