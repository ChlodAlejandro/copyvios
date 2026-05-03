import json
import time
import urllib.request
from json import JSONDecodeError

from flask import session

from .misc import cache


def get_eds_state():
    """Get a user's EDS access eligibility from the session. Delegate to actually checking if it's not there
    or if it's too old (one day cache)."""
    if session.get("username", None) is None or session.get("access_token") is None:
        return False

    if (
        session.get("username", None) is None
        or session.get("eds_cache_time", 0) < time.time() - 86400
    ):
        check_eds_state()
    return session.get("has_eds_access", False)


def check_eds_state():
    """Check if a user has EDS access and saves it."""
    username = session.get("username")
    try:
        eligibility_check = cache.bot.config.wiki["eds"]["eligibility_check"]
        request = urllib.request.urlopen(
            urllib.request.Request(eligibility_check % username, method="GET")
        )

        try:
            res = json.loads(request.read())
        except JSONDecodeError:
            # Invalid response. Assume ineligible (for safety).
            return False

        has_eds_access = res["wp_bundle_authorized"]
        save_eds_state(has_eds_access)
    except KeyError:
        # No eligibility check. Assume ineligible (for safety).
        return False


def save_eds_state(has_eds_access: bool):
    session["has_eds_access"] = has_eds_access
    session["eds_cache_time"] = time.time()
    session.modified = True
