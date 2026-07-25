<?php

namespace App\Filament\Resources\ChallengeCategoryResource\Pages;

use App\Filament\Resources\ChallengeCategoryResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditChallengeCategory extends EditRecord
{
    protected static string $resource = ChallengeCategoryResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
