
var socket = io.connect('http://localhost:3000');

socket.on('news', function (data) {

  console.log(data);

  document.getElementById('log').innerHTML += JSON.stringify(data) + '\n';

  socket.emit('my other event', { my: 'data' });
});