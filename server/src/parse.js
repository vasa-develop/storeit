import * as log from './log.js'
import * as S from 'string'
import * as git from './git.js'

const join = function(command, arg) {

  log.info('join with parameters ' + arg)
}

const add = (command, arg) => {

  git.add(arg.filePath)

}

export const parse = function(msg) {

  const command = JSON.parse(msg)

  const hmap = {
    'JOIN': join,
    'ADD': add
  }

  // TODO: catch the goddam exception
  hmap[command.command](command, parameters)
}