import http from 'k6/http';
import { check, sleep } from 'k6';

// k6 Load Test Configuration: 100 Virtual Users for 1 Minute
export const options = {
  stages: [
    { duration: '10s', target: 100 }, // Ramp-up to 100 VUs in 10 seconds
    { duration: '40s', target: 100 }, // Stay at 100 VUs for 40 seconds
    { duration: '10s', target: 0 },   // Ramp-down to 0 VUs in 10 seconds
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be under 500ms
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:5000';

export default function () {
  // Scenario 1: Health Check Endpoint
  const healthRes = http.get(`${BASE_URL}/health`);
  check(healthRes, {
    'Health status is 200': (r) => r.status === 200,
    'Health response healthy': (r) => r.json().status === 'healthy',
  });

  // Scenario 2: Home Root Endpoint
  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, {
    'Home status is 200': (r) => r.status === 200,
    'Backend is running': (r) => r.json().success === true,
  });

  // Scenario 3: Login Attempt with Payload
  const loginPayload = JSON.stringify({
    email: 'k6testuser@smileai.com',
    password: 'Password123!',
  });

  const loginParams = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const loginRes = http.post(`${BASE_URL}/login`, loginPayload, loginParams);
  check(loginRes, {
    'Login endpoint responded': (r) => r.status === 200 || r.status === 401,
  });

  // Pacing: sleep 100ms between VU iterations
  sleep(0.1);
}
