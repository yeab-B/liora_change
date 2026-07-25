<?php

namespace App\Filament\Resources\ChallengeTemplateResource\Pages;

use App\Filament\Resources\ChallengeTemplateResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListChallengeTemplates extends ListRecords
{
    protected static string $resource = ChallengeTemplateResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
