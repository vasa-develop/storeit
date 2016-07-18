import WebSocket from 'ws'

import {FacebookService, GoogleService} from './oauth'
import userFile from './user-file.js'
import {logger} from '../lib/log'
import Watcher from './watcher'
import {Command, Response, FileObj} from '../lib/protocol-objects'
import * as store from './store.js'
import tree from './tree.js'
import * as path from 'path'
import IPFSNode from './ipfs'

const MAX_RECO_TIME = 4

export default class Client {

  constructor() {
    this.recoTime = 1
    this.responseHandlers = {} // custom server response handlers
    this.ipfs = new IPFSNode()
    this.connect()
    this.fsWatcher = new Watcher(userFile.getStoreDir())
    this.fsWatcher.setEventHandler((ev) => this.handleFsEvent(ev))
  }

  auth(type) {
    let service
    switch (type) {
    case 'facebook':
      service = new FacebookService()
      type = 'fb'
      break
    case 'google':
      service = new GoogleService()
      type = 'gg'
      break
    case 'developer':
      return this.developer()
    default:
      return this.login() // TODO
    }

    return service.oauth()
      .then((tokens) => this.join(type, tokens.access_token))
      .then((cmd) =>
        this.addResponseHandler(cmd.uid, (data) => this.getRemoteTree(data))
      )
  }

  developer() {
    return this.join('gg', 'developer')
  }

  login() {
    throw {msg: 'StoreIt auth not implemented yet'}
  }

  connect() {
    const {SERVER_HOST, SERVER_PORT} = process.env
    this.sock = new WebSocket(`ws://${SERVER_HOST}:${SERVER_PORT}`)

    this.sock.on('open', () => {
      this.auth('developer')
      this.recoTime = 1
    })
    this.sock.on('close', () => this.reconnect())
    this.sock.on('error', () => logger.error('socket error occured'))
    this.sock.on('message', (data) => this.handleResponse(JSON.parse(data)))
  }

  reconnect() {
    logger.error(`attempting to reconnect in ${this.recoTime} seconds`)
    setTimeout(() => this.connect(), this.recoTime * 1000)

    if (this.recoTime < MAX_RECO_TIME) {
      ++this.recoTime
    }
  }

  addResponseHandler(uid, listener) {
    logger.debug('attaching response handler for command', uid)
    this.responseHandlers[uid] = listener
  }

  handleResponse(res) {
    let handler = this.responseHandlers[res.commandUid]
    if (handler != null) {
      this.responseHandlers[res.commandUid] = null
    }
    else {
      handler = this[`recv${res.command}`] // set to default handler
    }

    if (handler === null) {
      logger.error(`received unhandled response: ${JSON.stringify(res)}`)
      return null
    }
    else {
      return handler(res.parameters, res)
    }
  }

  answerSuccess(uid) {
    return this.sendObject(new Response(0, '', uid))
  }

  answerFailure(uid, code=1, msg='error') {
    return this.sendObject(new Response(code, msg, uid))
  }

  send(cmd, params) {
    let data = new Command(cmd, params)
    return this.sendObject(data, params)
  }

  sendObject(obj, params) {
    logger.info(`sending object ${JSON.stringify(obj)}`)

    return new Promise((resolve, reject) =>
      this.sock.send(JSON.stringify(obj), (err) => {
        if (err)
          return reject(err)
        this.addResponseHandler(obj.uid, (params, command) => {
          if (command.code === 0) {
            logger.debug('command ' + JSON.stringify(command) + ' is successful')
            return resolve(params)
          }
          return reject(command)
        })
      })
    )
  }

  join(authType, accessToken) {
    return this.send('JOIN', {authType, accessToken})
      .then((params) => logger.info(`tree is ${JSON.stringify(params.home)}`)) // TODO receive tree/home
  }

  recvFADD(params) {
    logger.info(`received FADD => ${JSON.stringify(params)}`)
    let status = []
    console.log(params)
    for (let file of params.files) {
      logger.info(`downloading file ${file.path} from ipfs`)
      status.push(this.ipfs.get(file.IPFSHash)
        .then((buf) => userFile.create(file.path, buf))
        .then(() => this.ipfs.add(file.path)))
        .catch((err) => logger.error(err))
    }
    return Promise.all(status)
  }

  recvRESP(params, command) {
    logger.info(`received ${command.code === 0 ? 'successful' : `failure ${command.code}`} response`)
  }

  recvFUPT(params) {
    logger.info(`received FUPT => ${JSON.stringify(params)}`)
    return this.recvFADD(params)
  }

  recvFDEL(params) {
    logger.info(`received FDEL => ${JSON.stringify(params)}`)
    let status = []
    for (let file of params.files) {
      status.push(userFile.del(file))
    }
    return Promise.all(status)
      .then((files) =>
        files.forEach((file) => logger.info(`removed file ${file.path}`))
      )
  }

  recvFMOV(params) {
    logger.info(`received FMOV => ${JSON.stringify(params)}`)
    return userFile.move(params.src, params.dest)
      .then((file) => logger.info(`moved file ${file.src} to ${file.dst}`))
  }

  recvFSTR(params) {
    logger.info(`received FMOV => ${JSON.stringify(params)}`)
    return store.FSTR(params.hash, params.keep)
      .then(() => this.answerSuccess())
      .catch((err) => logger.error('FSTR: ' + err))
  }

  sendFADD(filePath) {
    return tree.createTree(path.resolve('./') + path.sep + filePath, this.ipfs)
    .then((file) => this.send('FADD', {files: [file]}))
    .catch((err) => logger.error('FADD: ' + err.text))
  }

  sendFUPT(filePath) {
    return tree.createTree(path.resolve('./') + path.sep + filePath, this.ipfs)
    .then((file) => this.send('FUPT', {files: [file]}))
    .catch((err) => logger.error('FUPT: ' + err.text))
  }

  sendFDEL(filePath) {
    return this.send('FDEL', {files: [filePath.substr('storeit/'.length)]}) // QUICKFIX, no windows
    .catch((err) => logger.error('FDEL: ' + err.text))
  }

  sendFMOV(src, dst) {
    return this.send('FMOV', {src, dst})
    .catch((err) => logger.error('FMOV: ' + err.text))
  }

  handleFsEvent(ev) {
    let handler = this[`send${ev.type}`]
    if (handler) {
      handler.call(this, ev.path)
        .then(() => logger.debug('ok'))
        .catch((err) => logger.debug(err))

      // TODO: manage FMOV
    }
    else logger.warn(`[FileWatcher] unhandled event ${ev}`)
  }

  getRemoteTree(files) {
    return files
  }
}
