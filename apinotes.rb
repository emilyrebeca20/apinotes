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
:password => "",
)  

class User < ActiveRecord::Base
end

class ReturnCode
	CANEXEC =	1000	#Ejecutar la tarea
	UNAUTH = 	1001	#No autorizado
	LOGINREQ = 	1002	#Necesario login
	RNOTFOUND = 1003	#Recurso no encontrado
	BADLOGIN = 	1004	#Usuario o password inválido
end

class AccessResult
	attr_reader :code
	attr_reader :message
	attr_writer :code
	attr_writer :message
	def initialize(code,message)
		@code = code 
		@message = message
	end
end

#Recibe una solicitud devuelve un objeto de
#tipo User
def userlogin()
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

def userAuth(adminreq=false,loginreq=false,userid=nil)
	response = AccessResult.new(ReturnCode::CANEXEC,"Se pueden ejecutar las acciones.")	#Se crea un objeto de respuesta correcta
	if loginreq || adminreq then														#Si es necesario el login del usuario o del administrador
		basica = request.env["HTTP_AUTHORIZATION"].to_s.split("Basic ")					#Se obtiene el objeto User autenticado usando HTTP BA
		basicas = basica[1].to_s
		authdata = (Base64.decode64(basica.to_s)).split(':')
		username = authdata[0].to_s
		pass = authdata[1].to_s
		if not username.length or not pass.length then									#Si no se indica usuario o contraseña
			response.code = ReturnCode::LOGINREQ
			response.message = "Debe iniciar sesión."
			return response
		end
		userlog = User.where(email:username,password:pass).take
		if not userlog then																#Si no se encuentra el usuario con la contraseña
			response.code = ReturnCode::BADLOGIN
			response.message = "Usuario o contraseña inválidos."
			return response
		end
		if adminreq and userlog.role != "admin" then									#Si se requiere ser administrador y no lo es
			response.code = ReturnCode::UNAUTH
			response.message = "Usuario no autorizado"
			return response
		end
		if (userlog.role != "admin") and (userid.to_s != userlog.id.to_s) then
				#puts userlog.role
				#puts userlog.id
				#puts userid
				response.code = ReturnCode::UNAUTH
				response.message = "Usuario no autorizado 2"
				return response
		end
	end
	return response
end

get '/' do
	"Hello World"
end

#Todos los usuarios
get '/apinotes/user' do
	res = userAuth(adminreq=true,loginreq=true)
	if res.code == ReturnCode::CANEXEC then
		if User.all.length > 0 then			#Si hay algun usuario registrado
			User.all.to_json				#Se devuelven en formato to_json
		else  								#Si no hay usuario registrados
			ar = AccessResult.new(ReturnCode::RNOTFOUND,"No hay usuarios registrados")
			ar.to_json						#Se devuelve el error
		end
	else
		res.to_json
	end 

	# u = userlogin(request)					#Se verifica usuario y contrasena
	# if u then									#Si existe
	# 	if u.role == 'admin' then		#Tiene que ser administrador
	# 		if User.all.length > 0 then			#Si hay algun usuario registrado
	# 			User.all.to_json				#Se devuelven en formato to_json
	# 		else  								#Si no hay usuario registrados
	# 			"No hay usuarios registrados"	#Se devuelve el error
	# 		end
	# 	else 									#Si no es administrador
	# 		"No esta autorizado"				#Se devuelve el error
	# 	end
	# else 										#Si el usuario no existe
	# 	"Debe iniciar sesion"					#Se devuelve el error
	# end
end

#Un usuario
get '/apinotes/user/:id' do
	res = userAuth(adminreq=false,loginreq=true,userid=params[:id])	
	if res.code == ReturnCode::CANEXEC then
		u = User.where(id:params[:id]).first
		u.to_json
	else
		res.to_json
	end 

	# if ulog then								#Si existe
	# u = User.where(id:params[:id]).first	#Se obtiene el usuario requerido en la peticion
	# 	if u then								#Si este existe
	# 											#Se compara el id del login con el de la peticion
	# 		if ulog.id == u.id || ulog.role == 'admin' then				
	# 			u.to_json						#Si coincide, se devuelve en formato json
	# 		else 								#Si no coincide
	# 			"No esta autorizado"			#Se devuelve el error	 
	# 		end
	# 	else 									#Si el usuario buscado no existe
	# 		"El usuario no existe"				#Se devuelve el error
	# 	end
	# else 										#Si el usuario no existe
	# 	"Debe iniciar sesion"					#Se devuelve el error
	# end
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
	res = userAuth(adminreq=false,loginreq=true,userid=params[:id])	
	u = User.where(id:params[:id]).first
	if res.code == ReturnCode::CANEXEC then			
		name = params[:name]
		lastname = params[:lastname]
		email = params[:email]
		password = params[:password]
		question = params[:question]
		answer = params[:answer]
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
		res.to_json
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
