require "sinatra"
require "json"
require "mysql2"
require "active_record"


ActiveRecord::Base.establish_connection(  
:adapter => "mysql2",  
:host => "localhost",  
:database => "TASKAPP",
:username => "root",
:password => "20191602",
)  

class User < ActiveRecord::Base
end

get '/' do
	"Hello World"
end

#Todos los usuarios
get '/apinotes/user' do
	if User.all.length > 0 then
		User.all.to_json
	else
		"No hay usuario registrados"
	end
end

#Un usuario
get '/apinotes/user/:id' do
	u = User.where(id:params[:id]).first
	if u then
		u.to_json
	else
		"El usuario no existe"
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
put '/apinotes/user/:id' do
	u = User.where(id:params[:id]).first
	if u then
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
		"Usuario actualizado"
	else
		"El usuario no existe"
	end
end

#Borrar todos los usuarios
delete '/apinotes/user' do
	User.delete_all
	"Todos los usuarios fueron eliminados"
end

#Borrar un usuario
delete '/apinotes/user/:id' do
	u = User.where(id:params[:id]).first
	if u then
		u.destroy
		"Usuario eliminado"
	else
		"El usuario no existe"
	end
end


# /apinotes/login		 			(POST)
# /apinotes/logout		 		(GET)
# /apinotes/forgotpass	 		(POST)