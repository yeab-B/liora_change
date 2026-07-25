<?php

namespace App\Filament\Resources\ChallengeTemplateResource\Pages;

use App\Filament\Resources\ChallengeTemplateResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditChallengeTemplate extends EditRecord
{
    protected static string $resource = ChallengeTemplateResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
