import app from './src/app.js';
import { env } from './src/config/env.js';



app.listen(Number(env.PORT), '0.0.0.0', () => {
  console.log(`🚀 Server ready at http://0.0.0.0:${env.PORT}`);
  console.log(`🌍 Environment: ${env.NODE_ENV}`);
  console.log(`📡 Accepting connections on all interfaces`);
});