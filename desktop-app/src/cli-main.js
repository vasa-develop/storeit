import Client from './daemon/client'
import userFile from './daemon/user-file'
import logger from '../lib/log'

export const run = (program) => {
  if (program.store) userFile.setStoreDir(program.store)

  let client = new Client()
  client.connect()
    .then(() => client.auth('developer'))
    .catch(() => logger.error('An unexpected error occured'))
}
