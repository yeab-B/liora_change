<?php

namespace App\Exceptions\Api;

use RuntimeException;

/**
 * Base exception for domain/business-rule violations (e.g.
 * INVALID_STATUS_TRANSITION, CHALLENGE_NOT_ACTIVE, ALREADY_CLAIMED) that
 * should render as a consistent `{ message, code }` JSON envelope.
 *
 * Rendering is registered centrally in bootstrap/app.php so any controller
 * can simply `throw new BusinessRuleException(...)` instead of hand-rolling
 * a `response()->json([...], 422)` call.
 *
 * Several endpoints written before this issue (docs/mvp/issues/09-testing-qa.md)
 * already return ad-hoc 422 responses with a `code` field directly from the
 * controller (e.g. ChallengeController@activate via
 * InvalidStatusTransitionException, CheckInController@store,
 * RewardController@claimDaily). Their JSON shape already matches this
 * envelope, so they don't need to change — this class exists so any NEW
 * business-rule error added going forward has one obvious place to live.
 */
class BusinessRuleException extends RuntimeException
{
    public function __construct(
        string $message,
        public readonly string $code,
        public readonly int $status = 422,
    ) {
        parent::__construct($message);
    }
}
