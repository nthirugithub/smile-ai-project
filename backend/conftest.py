import os
import time
import threading
import urllib.request
from urllib.parse import urlparse
import pytest
from security_excel_reporter import reporter

BASE_URL = os.getenv("API_BASE_URL", "http://127.0.0.1:5000")

def is_server_running(url):
    try:
        req = urllib.request.Request(f"{url}/health")
        with urllib.request.urlopen(req, timeout=1) as resp:
            return resp.status in (200, 201, 204, 401, 403, 404)
    except Exception:
        return False

@pytest.fixture(scope="session", autouse=True)
def ensure_server_running():
    if is_server_running(BASE_URL):
        print(f"\n[conftest] Server is already running at {BASE_URL}")
        yield
        return

    print(f"\n[conftest] Server not detected at {BASE_URL}. Starting test server thread...")
    server = None
    try:
        from app import app, db
        from werkzeug.serving import make_server

        with app.app_context():
            db.create_all()

        parsed = urlparse(BASE_URL)
        host = parsed.hostname or "127.0.0.1"
        port = parsed.port or 5000

        server = make_server(host, port, app)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()

        start_time = time.time()
        while time.time() - start_time < 30:
            if is_server_running(BASE_URL):
                print(f"[conftest] Test server successfully started at {BASE_URL}")
                break
            time.sleep(0.5)
    except Exception as e:
        print(f"\n[conftest] Warning: Failed to start embedded test server: {e}")

    yield

    if server:
        print("\n[conftest] Shutting down test server thread...")
        server.shutdown()

@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    report = outcome.get_result()
    if report.when == "call":
        test_id = item.name
        method_name = getattr(item.function, "__name__", item.name)
        duration = report.duration
        if report.passed:
            status = "PASSED"
            failure_reason = ""
        elif report.failed:
            status = "FAILED"
            failure_reason = str(report.longrepr)
        else:
            status = "SKIPPED"
            failure_reason = ""

        reporter.add_result(test_id, method_name, status, duration, failure_reason)

def pytest_sessionfinish(session, exitstatus):
    report_path = os.path.join("reports", "Security_Controls_Audit_Report.xlsx")
    reporter.generate_report(report_path, BASE_URL)
