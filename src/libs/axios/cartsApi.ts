import api from '.';

const CARTS_URL = '/carts'

const cartsApi = {
  list: () => api.get(CARTS_URL)
}

export default cartsApi;