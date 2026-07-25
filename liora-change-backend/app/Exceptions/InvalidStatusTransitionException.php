<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Thrown when a challenge (or other status-machine-driven aggregate) is
 * asked to move into a status that its current status does not allow.
 * Controllers catch this and render it as 422 INVALID_STATUS_TRANSITION.
 */
class InvalidStatusTransitionException extends RuntimeException
{
}
