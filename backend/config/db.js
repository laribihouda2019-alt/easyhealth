const { Pool } = require('pg');//importation class pool(posgresql)
const ENV = require('./env');//import variables d'environnement

let _pool = null;//stocke variable
let _initPromise = null;//stocke promesse d'itialisation pour eviter creer plusieurs pool simultanement

async function initPool() {
  if (_pool) return _pool;//si pool existe retourner sans creer nouveau
  if (_initPromise) return _initPromise;//si creation est en cours attendre meme promesse pas ecrir nouveau

  _initPromise = (async () => {
    _pool = new Pool({
      connectionString: ENV.DATABASE_URL,//connection with base de donnees
      ssl: ENV.DB_SSL,//chifferement ssl
      max: ENV.DB_MAX_CONNECTIONS,//nombre max de connexion simultanees
      idleTimeoutMillis: ENV.DB_IDLE_TIMEOUT_MS,//duree en milli avant fermer connexion inactive
      connectionTimeoutMillis: ENV.DB_CONNECTION_TIMEOUT_MS,//temps max d'attente pour ouvrir nouvelle connexion
    });

    _pool.on('error', (err) => {
      console.error('Unexpected PG client error:', err);//ecoute des erreurs
    });

    return _pool;
  })();

  return _initPromise;
}

async function query(text, params, options = {}) {    //executer requetes sql
  const pool = await initPool();
  const timeoutMs = options.timeoutMs || ENV.DB_QUERY_TIMEOUT_MS; //delai d'expiration

  const timeoutPromise = new Promise((_, reject) => {
    const id = setTimeout(() => {
      clearTimeout(id);
      reject(new Error(`Database query timeout after ${timeoutMs}ms`));
    }, timeoutMs);
  });

  return Promise.race([pool.query(text, params), timeoutPromise]);
}

module.exports = {
  query,
  get pool() {
    return _pool;
  },
};
