window.addEventListener('load', function() {
    // Get environment variables
    const envVars = {
        GROQ_API_KEY: process.env.GROQ_API_KEY || ''
    };
    
    // Store in localStorage
    for (const [key, value] of Object.entries(envVars)) {
        if (value) {
            window.localStorage.setItem(key, value);
        }
    }
});
