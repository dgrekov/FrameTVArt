"""
SamsungTVWS - Samsung Smart TV WS API wrapper

Copyright (C) 2019 DSR! <xchwarze@gmail.com>

SPDX-License-Identifier: LGPL-3.0
"""

import logging
import os
import ssl
from typing import Any, Dict, Optional

import urllib3

from . import connection, exceptions, helper

_LOGGING = logging.getLogger(__name__)


def _env_truthy(name: str, default: str = "1") -> bool:
    return os.environ.get(name, default).lower() not in {"0", "false", "no"}


_FRAME_TV_CERT_PATH = os.environ.get("FRAME_TV_CERT_PATH")
if _FRAME_TV_CERT_PATH and not os.path.exists(_FRAME_TV_CERT_PATH):
    _FRAME_TV_CERT_PATH = None


def _build_pool_manager() -> urllib3.PoolManager:
    context = ssl.create_default_context()
    if _FRAME_TV_CERT_PATH:
        context.load_verify_locations(_FRAME_TV_CERT_PATH)

    assert_hostname: Optional[bool] = None

    if not _env_truthy("FRAME_TV_TLS_VERIFY", "1"):
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        assert_hostname = False

    if _env_truthy("FRAME_TV_DISABLE_HOSTNAME_CHECK", "1"):
        context.check_hostname = False
        assert_hostname = False

    if context.verify_mode == ssl.CERT_NONE:
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    return urllib3.PoolManager(ssl_context=context, assert_hostname=assert_hostname)


_HTTP = _build_pool_manager()


class SamsungTVRest(connection.SamsungTVWSBaseConnection):
    def __init__(
        self,
        host: str,
        port: int = 8001,
        timeout: Optional[float] = None,
    ) -> None:
        super().__init__(
            host,
            endpoint="",
            port=port,
            timeout=timeout,
        )

    def _rest_request(self, target: str, method: str = "GET") -> Dict[str, Any]:
        url = self._format_rest_url(target)
        try:
            response = _HTTP.request(method, url, timeout=self.timeout)
            return helper.process_api_response(response.data.decode("utf-8"))
        except urllib3.exceptions.HTTPError as err:
            raise exceptions.HttpApiError(
                "TV unreachable or feature not supported on this model."
            ) from err

    def rest_power_state(self) -> bool:
        _LOGGING.debug("Get PowerState via rest api")
        return self._rest_request("").get('device', {}).get('PowerState', 'off') == 'on'

    def get_model_year(self) -> int:
        model = self._rest_request("").get('device', {}).get('model', '0_0')
        return int(model.split('_')[0])

    def rest_device_info(self) -> Dict[str, Any]:
        _LOGGING.debug("Get device info via rest api")
        return self._rest_request("")

    def rest_app_status(self, app_id: str) -> Dict[str, Any]:
        _LOGGING.debug("Get app %s status via rest api", app_id)
        return self._rest_request("applications/" + app_id)

    def rest_app_run(self, app_id: str) -> Dict[str, Any]:
        _LOGGING.debug("Run app %s via rest api", app_id)
        return self._rest_request("applications/" + app_id, "POST")

    def rest_app_close(self, app_id: str) -> Dict[str, Any]:
        _LOGGING.debug("Close app %s via rest api", app_id)
        return self._rest_request("applications/" + app_id, "DELETE")

    def rest_app_install(self, app_id: str) -> Dict[str, Any]:
        _LOGGING.debug("Install app %s via rest api", app_id)
        return self._rest_request("applications/" + app_id, "PUT")
