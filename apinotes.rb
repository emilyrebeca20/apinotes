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
	u = User.where(email:username,password:pass).take
	return u
end

get '/' do
	"Hello World"
end

#Todos los usuarios
get '/apinotes/user' do
	u = userlogin(request)						#Se verifica usuario y contrasena
	if u then									#Si existe
		if u.role == 'admin' then		#Tiene que ser administrador
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
			if ulog.id == u.id || ulog.role == 'admin' then				
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
#Verificar que el email no sea duplicado!!!
post '/apinotes/user' do
	name = params[:name]
	lastname = params[:lastn]
	email = params[:email]
	password = params[:pass]
	question = params[:secquest]
	answer = params[:secans]

	u = User.new
	u.name = name
	u.last_name = lastname
	u.email = email
	u.question = question
	u.answer = answer
	u.password = password
	u.role = 'user'
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
			if ulog.id == u.id || ulog.role == 'admin' then				
				name = params[:name]
				lastname = params[:lastn]
				email = params[:email]
				password = params[:pass]
				question = params[:secquest]
				answer = params[:secans]
				if name then
					u.update(name:name)
					# u.nombre = name
				end
				if lastname then
					u.update(last_name:lastname)
					# u.apellido = lastname
				end
				if email then
					u.update(email:email)
					# u.email = email
				end
				if question then
					u.update(question:question)
					# u.respuesta_pregunta = answer
				end
				if answer then
					u.update(answer:answer)
					# u.respuesta_pregunta = answer
				end
				if password then
					u.update(password:password)
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
		"Debe iniciar sesion"					#Se devuelve el error
	end 						
end

#Borrar todos los usuarios
delete '/apinotes/user' do
	u = userlogin(request)						#Se verifica usuario y contrasena
	if u then									#Si existe
		if u.role == 'admin' then		#Tiene que ser administrador
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
			if ulog.id == u.id || ulog.role == 'admin' then				
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
