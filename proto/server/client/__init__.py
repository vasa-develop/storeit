"""Relates to client."""

from log import logger
import tree
import database
import chunk
import os


class Client:

    username = str()
    port = str()
    user_tree = None
    transport = None

    def __init__(self, username: str, port: str, tree: tree.Tree, transport):

        logger.info('{} has joined on port {}'.format(username, port))

        self.username = username
        self.port = port
        self.user_tree = tree
        self.transport = transport

    def send_cmd(self, msg):
        logger.debug('to {}: {}'.format(self.username, msg))

        if self.transport is None:
            logger.error('client has no transport registered')
            return

        msg += '\r\n'
        self.transport.write(msg.encode())

    def __del__(self):
        logger.debug('{} is disconnecting'.format(self.username))
        chunk.remove_user(self)

    def find_in_tree(self, subtree):

        def find_tree_rec(path, tr):

            path_sep = path.split('/', 1)

            if len(path_sep) == 2:
                return tr['files'], path_sep[1]
            elif path_sep[0] not in tr['files']:
                logger.error('error {} is invalid'.format(subtree['path']))
                return None, None
            else:
                # TODO: handle deletion. Maybe if the thing exists and
                # has same metadata delete it
                return find_tree_rec(path_sep[1], tr['files'][path_sep[0]])

        usr_tree_dict = self.user_tree.raw_tree
        return find_tree_rec(os.path.normpath(subtree['path']), usr_tree_dict)


class CliManager:

    clients = dict()
    transports = dict()

    def __init__(self):
        pass

    def add_cli(self, username: str, port: str, tree_sent: str, transport):

        tree_database = database.find_user(username, 'pass')

        if tree_database is None:
            logger.info('user {} does not exists'.format(username))
            return None

        ts = tree.Tree(tree_sent)
        td = tree.Tree(tree_database)

        cli = Client(username, port, ts, transport)

        self.clients[username] = cli
        self.transports[transport] = username

        tree.Tree.process_subtree(cli, ts.raw_tree, td.raw_tree)

        logger.debug('tree has been processed for {}'.format(username))

        database.save_new_tree(username, ts.raw_tree)

        return cli

    def get_cli(self, username: str):

        if username not in self.clients:
            return None

        return self.clients[username]
