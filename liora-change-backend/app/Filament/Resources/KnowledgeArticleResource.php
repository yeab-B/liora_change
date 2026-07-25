<?php

namespace App\Filament\Resources;

use App\Filament\Resources\KnowledgeArticleResource\Pages;
use App\Models\KnowledgeArticle;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class KnowledgeArticleResource extends Resource
{
    protected static ?string $model = KnowledgeArticle::class;

    protected static ?string $navigationIcon = 'heroicon-o-book-open';

    protected static ?string $navigationGroup = 'AI Coach';

    /**
     * Re-chunking on save is handled by App\Models\KnowledgeArticle's
     * `saved` event (App\Services\Ai\KnowledgeChunker), so both this
     * resource's create/edit pages and any other write path (e.g. the
     * seeder) always keep `knowledge_chunks` in sync.
     */
    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('title')
                    ->required()
                    ->maxLength(255),
                Forms\Components\Select::make('category')
                    ->options([
                        'habits' => 'Habits',
                        'recovery' => 'Recovery',
                        'streaks' => 'Streaks',
                        'faq' => 'FAQ',
                    ])
                    ->searchable()
                    ->native(false),
                Forms\Components\Toggle::make('is_active')
                    ->default(true)
                    ->required(),
                Forms\Components\Textarea::make('body')
                    ->required()
                    ->rows(12)
                    ->helperText('Split into paragraphs (blank line between them) — each becomes a chunk the chatbot can retrieve.')
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('title')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('category')
                    ->badge()
                    ->sortable(),
                Tables\Columns\IconColumn::make('is_active')
                    ->boolean()
                    ->sortable(),
                Tables\Columns\TextColumn::make('chunks_count')
                    ->label('Chunks')
                    ->counts('chunks'),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_active'),
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
            'index' => Pages\ListKnowledgeArticles::route('/'),
            'create' => Pages\CreateKnowledgeArticle::route('/create'),
            'edit' => Pages\EditKnowledgeArticle::route('/{record}/edit'),
        ];
    }
}
