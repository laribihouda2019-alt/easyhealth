const { Server } = require('socket.io');

let io;
const userSockets = new Map(); //userId -> socketId

function initSocket(server) {
    io = new Server(server, {
        cors: {
            origin: '*', //Adjust for security in production
            methods: ['GET', 'POST']
        }
    });

    io.on('connection', (socket) => {
        const userId = socket.handshake.query.userId;
        

        if (userId) {
            userSockets.set(userId, socket.id);
        }

        socket.on('disconnect', () => {
            
            if (userId) {
                userSockets.delete(userId);
            }
        });
    });

    
    return io;
}

function getIo() {
    if (!io) {
        throw new Error('Socket.io not initialized');
    }
    return io;
}

function sendToUser(userId, event, data) {
    const socketId = userSockets.get(userId);
    if (socketId) {
        io.to(socketId).emit(event, data);
        return true;
    }
    return false;
}

function broadcastUpdate(event, data) {
    if (io) {
        io.emit(event, data);
    }
}

module.exports = {
    initSocket,
    getIo,
    sendToUser,
    broadcastUpdate
};

