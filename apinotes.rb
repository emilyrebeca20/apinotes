require "sinatra"
require "json"
require "mysql2"
require "active_record"
require "base64"


ActiveRecord::Base.establish_connection(  
:adapter => "mysql2",  
:host => "localhost",  
:database => "TASKAPP",
:username => "root",
:password => "20191602",
)  

class User < ActiveRecord::Base
end

#Recibe una solicitud devuelve un objeto de
#tipo User
def userlogin(req)
	basica = request.env["HTTP_AUTHORIZATION"].to_s.split("Basic ")
	basicas = basica[1].to_s
	authdata = (Base64.decode64(basica.to_s)).split(':')
	username = authdata[0].to_s
	pass = authdata[1].to_s
	puts "Usuario: #{username}"
	puts "Password: #{pass}"
	u = User.where(email:username,contrasena:pass).take
	return u
end

get '/' do
	"Hello World"
end

#Todos los usuarios
get '/apinotes/user' do
	u = userlogin(request)						#Se verifica usuario y contrasena
	if u then									#Si existe
		if u.rol == 'administrador' then		#Tiene que ser administrador
			if User.all.length > 0 then			#Si hay algun usuario registrado
				User.all.to_json				#Se devuelven en formato to_json
			else  								#Si no hay usuario registrados
				"No hay usuarios registrados"	#Se devuelve el error
			end
		else 									#Si no es administrador
			"No esta autorizado"				#Se devuelve el error
		end
	else 										#Si el usuario no existe
		"Debe iniciar sesion"					#Se devuelve el error
	end
end

#Un usuario
get '/apinotes/user/:id' do
	ulog = userlogin(request)					#Se verifica usuario y contrasena
	if ulog then								#Si existe
		u = User.where(id:params[:id]).first	#Se obtiene el usuario requerido en la peticion
		if u then								#Si este existe
												#Se compara el id del login con el de la peticion
			if ulog.id == u.id || ulog.rol == 'administrador' then				
				u.to_json						#Si coincide, se devuelve en formato json
			else 								#Si no coincide
				"No esta autorizado"			#Se devuelve el error	 
			end
		else 									#Si el usuario buscado no existe
			"El usuario no existe"				#Se devuelve el error
		end
	else 										#Si el usuario no existe
		"Debe iniciar sesion"					#Se devuelve el error
	end
end

#Crear un usuario
post '/apinotes/user' do
	name = params[:nombre]
	lastname = params[:apellido]
	email = params[:correoe]
	answer = params[:resps]
	password = params[:contrasena]

	u = User.new
	u.nombre = name
	u.apellido = lastname
	u.email = email
	u.respuesta_pregunta = answer
	u.contrasena = password
	u.rol = 'usuario'
	u.save

	# puts name 
	# puts lastname 
	# puts email 
	# puts answer 
	# puts password

	"Usuario creado"
end

#Actualizar un usuario
#Para agendar actualizar las fechas
#Para recuperar password verificar respuesta de seguridad
#y reemplazar la contraseña
put '/apinotes/user/:id' do
	ulog = userlogin(request)					#Se verifica usuario y contrasena
	if ulog then								#Si existe
		u = User.where(id:params[:id]).first	#Se obtiene el usuario requerido en la peticion
		if u then								#Si este existe
												#Se compara el id del login con el de la peticion
			if ulog.id == u.id || ulog.rol == 'administrador' then				
				name = params[:nombre]
				lastname = params[:apellido]
				email = params[:correoe]
				answer = params[:resps]
				password = params[:contrasena]
				if name then
					u.update(nombre:name)
					# u.nombre = name
				end
				if lastname then
					u.update(apellido:lastname)
					# u.apellido = lastname
				end
				if email then
					u.update(email:email)
					# u.email = email
				end
				if answer then
					u.update(respuesta_pregunta:answer)
					# u.respuesta_pregunta = answer
				end
				if password then
					u.update(contrasena:password)
					# u.contrasena = password
				end
				"Usuario actualizado"			#Se actualiza el usuario
			else
				"No esta autorizado"			#Se devuelve el error
			end
		else 									#Si el usuario buscado no existe
			"El usuario no existe"				#Se devuelve el error
		end
	else 										#Si el usuario no existe
		"El usuario no existe"					#Se devuelve el error
	end 						
end

#Borrar todos los usuarios
delete '/apinotes/user' do
	u = userlogin(request)						#Se verifica usuario y contrasena
	if u then									#Si existe
		if u.rol == 'administrador' then		#Tiene que ser administrador
			if User.all.length > 0 then			#Si hay algun usuario registrado
				User.delete_all					#Se eliminan todos
				"Todos los usuarios fueron eliminados"
			else  								#Si no hay usuario registrados
				"No hay usuarios registrados"	#Se devuelve el error
			end
		else 									#Si no es administrador
			"No esta autorizado"				#Se devuelve el error
		end
	else 										#Si el usuario no existe
		"Debe iniciar sesion"					#Se devuelve el error
	end
end

#Borrar un usuario
delete '/apinotes/user/:id' do
	ulog = userlogin(request)					#Se verifica usuario y contrasena
	if ulog then								#Si existe
		u = User.where(id:params[:id]).first	#Se obtiene el usuario requerido en la peticion
		if u then								#Si este existe
												#Se compara el id del login con el de la peticion
			if ulog.id == u.id || ulog.rol == 'administrador' then				
				u.destroy
				"Usuario eliminado"
			else 								#Si no coincide
				"No esta autorizado"			#Se devuelve el error	 
			end
		else 									#Si el usuario buscado no existe
			"El usuario no existe"				#Se devuelve el error
		end
	else 										#Si el usuario no existe
		"Debe iniciar sesion"					#Se devuelve el error
	end
end
