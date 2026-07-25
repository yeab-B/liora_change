<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ChallengeTemplateResource\Pages;
use App\Models\ChallengeTemplate;
use App\Shared\Enums\ChallengeDifficulty;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Str;

class ChallengeTemplateResource extends Resource
{
    protected static ?string $model = ChallengeTemplate::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    protected static ?string $navigationGroup = 'Challenges';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('title')
                    ->required()
                    ->maxLength(255),
                Forms\Components\Textarea::make('description')
                    ->columnSpanFull(),
                Forms\Components\Select::make('difficulty')
                    ->options(collect(ChallengeDifficulty::cases())
                        ->mapWithKeys(fn (ChallengeDifficulty $case) => [$case->value => Str::headline($case->value)])
                        ->all())
                    ->default(ChallengeDifficulty::Beginner->value)
                    ->required(),
                Forms\Components\TextInput::make('duration_days')
                    ->numeric()
                    ->minValue(1)
                    ->maxValue(90)
                    ->default(7)
                    ->required(),
                Forms\Components\Select::make('category_id')
                    ->relationship('category', 'name')
                    ->searchable()
                    ->preload(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('title')
                    ->searchable(),
                Tables\Columns\TextColumn::make('category.name')
                    ->label('Category')
                    ->sortable(),
                Tables\Columns\TextColumn::make('difficulty')
                    ->badge()
                    ->sortable(),
                Tables\Columns\TextColumn::make('duration_days')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListChallengeTemplates::route('/'),
            'create' => Pages\CreateChallengeTemplate::route('/create'),
            'edit' => Pages\EditChallengeTemplate::route('/{record}/edit'),
        ];
    }
}
