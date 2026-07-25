<?php

namespace App\Filament\Resources;

use App\Filament\Resources\FeaturedChallengeResource\Pages;
use App\Filament\Resources\FeaturedChallengeResource\RelationManagers;
use App\Models\FeaturedChallenge;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class FeaturedChallengeResource extends Resource
{
    protected static ?string $model = FeaturedChallenge::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('challenge_id')
                    ->required(),
                Forms\Components\TextInput::make('display_priority')
                    ->required()
                    ->numeric()
                    ->default(0),
                Forms\Components\DateTimePicker::make('publish_date'),
                Forms\Components\DateTimePicker::make('expiration_date'),
                Forms\Components\Toggle::make('is_visible')
                    ->required(),
                Forms\Components\TextInput::make('campaign_support'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('ID')
                    ->searchable(),
                Tables\Columns\TextColumn::make('challenge_id')
                    ->searchable(),
                Tables\Columns\TextColumn::make('display_priority')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('publish_date')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('expiration_date')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\IconColumn::make('is_visible')
                    ->boolean(),
                Tables\Columns\TextColumn::make('campaign_support')
                    ->searchable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
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
            'index' => Pages\ListFeaturedChallenges::route('/'),
            'create' => Pages\CreateFeaturedChallenge::route('/create'),
            'edit' => Pages\EditFeaturedChallenge::route('/{record}/edit'),
        ];
    }
}
