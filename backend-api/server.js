const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const app = express();

app.use(express.json());
app.use(cors());

const archivoMascotas = path.join(__dirname, 'mascotas.json');
const archivoUsuarios = path.join(__dirname, 'usuarios.json');

// Funciones auxiliares para mascotas
function leerMascotas() {
  if (!fs.existsSync(archivoMascotas)) {
    const iniciales = [
      { id: 1, nombre: 'Firulais', tipo: 'Perro', estado: 'Perdido', descripcion: 'Se perdió cerca al parque central.', autor: 'Sistema' },
      { id: 2, nombre: 'Michi', tipo: 'Gato', estado: 'Adopción', descripcion: 'Busca hogar amoroso y seguro.', autor: 'Sistema' },
      { id: 3, nombre: 'Max', tipo: 'Perro', estado: 'Encontrado', descripcion: 'Encontrado vagando por la avenida principal.', autor: 'Sistema' }
    ];
    fs.writeFileSync(archivoMascotas, JSON.stringify(iniciales, null, 2));
    return iniciales;
  }
  const data = fs.readFileSync(archivoMascotas, 'utf8');
  return JSON.parse(data);
}

function escribirMascotas(mascotas) {
  fs.writeFileSync(archivoMascotas, JSON.stringify(mascotas, null, 2));
}

// Funciones auxiliares para usuarios
function leerUsuarios() {
  if (!fs.existsSync(archivoUsuarios)) {
    fs.writeFileSync(archivoUsuarios, JSON.stringify([], null, 2));
    return [];
  }
  const data = fs.readFileSync(archivoUsuarios, 'utf8');
  return JSON.parse(data);
}

function escribirUsuarios(usuarios) {
  fs.writeFileSync(archivoUsuarios, JSON.stringify(usuarios, null, 2));
}

// 1. RUTA DE REGISTRO
app.post('/api/register', (req, res) => {
  const { nombre, apellido, email, password } = req.body;
  if (!nombre || !email || !password) {
    return res.status(400).json({ mensaje: 'Faltan campos obligatorios' });
  }

  const usuarios = leerUsuarios();
  const existe = usuarios.find(u => u.email === email);
  if (existe) {
    return res.status(400).json({ mensaje: 'El correo ya está registrado' });
  }

  const nuevoUsuario = { nombre, apellido, email, password };
  usuarios.push(nuevoUsuario);
  escribirUsuarios(usuarios);

  // Token simulado con el nombre del usuario integrado
  const fakeJwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." + Buffer.from(JSON.stringify(nuevoUsuario)).toString('base64') + ".signature";

  res.json({
    mensaje: 'Usuario registrado con éxito',
    token: fakeJwtToken,
    usuario: { nombre: `${nombre} ${apellido || ''}`.trim(), email }
  });
});

// 2. RUTA DE LOGIN
app.post('/api/login', (req, res) => {
  const { email, password } = req.body;
  const usuarios = leerUsuarios();
  
  const usuarioEncontrado = usuarios.find(u => u.email === email && u.password === password);
  
  if (usuarioEncontrado) {
    const fakeJwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." + Buffer.from(JSON.stringify(usuarioEncontrado)).toString('base64') + ".signature";
    
    return res.json({
      mensaje: 'Login exitoso',
      token: fakeJwtToken,
      usuario: { nombre: `${usuarioEncontrado.nombre} ${usuarioEncontrado.apellido || ''}`.trim(), email }
    });
  }
  
  res.status(400).json({ mensaje: 'Correo o contraseña incorrectos' });
});

// Middleware de Autorización
app.use((req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (req.method !== 'GET' && !authHeader) {
    return res.status(401).json({ mensaje: 'No autorizado: Debes iniciar sesión.' });
  }
  next();
});

app.get('/api/mascotas', (req, res) => {
  const mascotas = leerMascotas();
  res.json(mascotas);
});

// 3. POST DE MASCOTAS (Captura quién lo creó usando el token/autor)
app.post('/api/mascotas', (req, res) => {
  const mascotas = leerMascotas();
  
  // Extraemos de forma simple el autor del header de autorización si viene adjunto
  let autorReporte = 'Usuario Anónimo';
  try {
    const authHeader = req.headers['authorization'];
    const tokenPart = authHeader.split('.')[1];
    const decoded = JSON.parse(Buffer.from(tokenPart, 'base64').toString('utf8'));
    autorReporte = decoded.nombre ? `${decoded.nombre} ${decoded.apellido || ''}`.trim() : decoded.email;
  } catch (e) {
    autorReporte = 'Usuario Autenticado';
  }

  const nuevaMascota = { 
    id: mascotas.length > 0 ? mascotas[mascotas.length - 1].id + 1 : 1, 
    nombre: req.body.nombre || 'Sin nombre',
    tipo: req.body.tipo || 'Mascota',
    estado: req.body.estado || 'Perdido',
    descripcion: req.body.descripcion || 'Sin descripción',
    autor: autorReporte // <--- Aquí queda grabado a nombre de quién lo hizo
  };

  mascotas.push(nuevaMascota);
  escribirMascotas(mascotas);

  res.json({ mensaje: 'Reporte registrado con éxito', mascota: nuevaMascota });
});

app.listen(3000, () => {
  console.log('API de Huellitas con Registro y Autores corriendo en http://localhost:3000');
});