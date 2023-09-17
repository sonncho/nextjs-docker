import axios, { AxiosInstance, InternalAxiosRequestConfig } from "axios";

const axiosInstance: AxiosInstance = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
  },
});

/**
 * http request 보내기직전 호출되는 함수.
 * @param config
 */
axiosInstance.interceptors.request.use(
  async (config: InternalAxiosRequestConfig) => {
    // if (token) {
    //   config.headers['Content-Type'] = 'application/json';
    //   config.headers.Authorization = token;
    // }
    return config;
  },
  (err) => {
    return Promise.reject(err);
  }
);

export default axiosInstance;