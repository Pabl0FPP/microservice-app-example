// Configuration loader for dynamic API URLs
let config = null;

// Load configuration from server-generated config.js
export const loadConfig = async () => {
  if (config) {
    return config;
  }

  try {
    // Dynamically import the config from the server
    const response = await fetch('/config.js');
    const configText = await response.text();
    
    // Execute the config script to get window.CONFIG
    eval(configText);
    config = window.CONFIG;
    
    return config;
  } catch (error) {
    console.error('Failed to load configuration:', error);
    
    // Fallback to default values (for development)
    config = {
      AUTH_API_URL: 'http://localhost:8000',
      TODOS_API_URL: 'http://localhost:3000', 
      USERS_API_URL: 'http://localhost:8080'
    };
    
    return config;
  }
};

// Get API base URLs
export const getApiUrls = async () => {
  const cfg = await loadConfig();
  return {
    authApi: `https://${cfg.AUTH_API_URL}`,
    todosApi: `https://${cfg.TODOS_API_URL}`,
    usersApi: `https://${cfg.USERS_API_URL}`
  };
};