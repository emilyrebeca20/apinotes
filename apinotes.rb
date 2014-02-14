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
#No autorizado
class User < ActiveRecord::Base
end

class Task < ActiveRecord::Base
end 

class ReturnCode
	CANEXEC =	1000	#Ejecutar la tarea
	GENEVENT = 	1001	#Evento general
	GENEXCEPT =	1002	#Excepcion general
	LOGINREQ = 	1003	#Necesario login
	RNOTFOUND = 1004	#Recurso no encontrado
	BADLOGIN = 	1005	#Usuario o password inválido
	UNAUTH = 	1006	#Usuario no autorizado
	ADMINREQ = 	1007	#Necesario ser administrador
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

def userlogged()
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
		if username.length == 0 or pass.length == 0 then									#Si no se indica usuario o contraseña
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
			response.code = ReturnCode::ADMINREQ
			response.message = "No es administrador"
			return response
		end
		if (userlog.role != "admin") and (userid.to_s != userlog.id.to_s) then			#Si se quiere hacer una consulta de otro usuario
				response.code = ReturnCode::UNAUTH
				response.message = "Usuario no autorizado"
				return response
		end
	end
	return response
end

#Olvido contraseña
get '/apinotes/user/question' do
	u = User.where(email:params[:email]).first
	if u then 
		AccessResult.new(ReturnCode::GENEVENT,u.question).to_json
	else
		AccessResult.new(ReturnCode::RNOTFOUND,"No existe el usuario").to_json
	end
end

#Reiniciar contraseña
put '/apinotes/user/password' do
	email = params[:email]
	npass = params[:password]
	answer = params[:answer]
	if email and npass and answer then
		u = User.where(email:params[:email]).first	
		if u then			
			if answer.to_s == u.answer.to_s then
				u.update(password:npass)
				AccessResult.new(ReturnCode::GENEVENT,"Contraseña reinciada exitosamente").to_json
			else
				AccessResult.new(ReturnCode::GENEVENT,"Respuesta inválida").to_json
			end
		else
			AccessResult.new(ReturnCode::RNOTFOUND,"El usuario no existe").to_json
		end
	else
		AccessResult.new(ReturnCode::GENEXCEPT,"Faltan parametros").to_json
	end  						
end

#Todos los usuarios
get '/apinotes/user' do
	res = userAuth(adminreq=true,loginreq=true)
	if res.code == ReturnCode::CANEXEC then
		if User.all.length > 0 then			#Si hay algun usuario registrado
			User.all.to_json				#Se devuelven en formato to_json
		else  								#Si no hay usuario registrados
			AccessResult.new(ReturnCode::RNOTFOUND,"No hay usuarios registrados").to_json
		end
	else
		res.to_json
	end 
end

#Un usuario
get '/apinotes/user/:idu' do
	res = userAuth(adminreq=false,loginreq=true,userid=params[:idu])	
	if res.code == ReturnCode::CANEXEC then
		u = User.where(id:params[:idu]).first
		if u then
			u.to_json
		else
			AccessResult.new(ReturnCode::GENEVENT,"El usuario no existe").to_json
		end
	else
		res.to_json
	end 
end

#Crear un usuario
post '/apinotes/user' do
	name = params[:name]
	lastname = params[:lastname]
	email = params[:email]
	password = params[:password]
	question = params[:question]
	answer = params[:answer]

	if name and lastname and email and password and question and answer then
		du = User.where(email:email).first
		if not du then
			u = User.new
			u.name = name
			u.last_name = lastname
			u.email = email
			u.question = question
			u.answer = answer
			u.password = password
			u.role = 'user'
			u.save
			AccessResult.new(ReturnCode::GENEVENT,"Usuario creado").to_json
		else
			AccessResult.new(ReturnCode::GENEXCEPT,"El usuario ya existe").to_json
		end
	else
		AccessResult.new(ReturnCode::GENEXCEPT,"Faltan parametros").to_json
	end
end

#Actualizar un usuario
put '/apinotes/user/:idu' do
	res = userAuth(adminreq=false,loginreq=true,userid=params[:idu])	
	if res.code == ReturnCode::CANEXEC then	
		u = User.where(id:params[:idu]).first
		if u then		
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
			AccessResult.new(ReturnCode::GENEVENT,"Usuario actualizado").to_json
		else
			AccessResult.new(ReturnCode::RNOTFOUND,"El usuario no existe").to_json
		end
	else
		res.to_json
	end 						
end

#Borrar todos los usuarios
delete '/apinotes/user' do
	res = userAuth(adminreq=true,loginreq=true)	
	if res.code == ReturnCode::CANEXEC then
		if User.where(role:'user').length > 0 then			#Si hay algun usuario registrado
			User.delete_all("role = 'user'")					#Se eliminan todos
			AccessResult.new(ReturnCode::GENEVENT,"Todos los usuarios fueron eliminados").to_json
		else  								#Si no hay usuario registrados
			AccessResult.new(ReturnCode::RNOTFOUND,"No hay usuarios registrados").to_json
		end
	else
		res.to_json
	end
end

#Borrar un usuario
delete '/apinotes/user/:idu' do
	res = userAuth(adminreq=false,loginreq=true,userid=params[:idu])	
	if res.code == ReturnCode::CANEXEC then
		u = User.where(id:params[:idu]).first	#Se obtiene el usuario requerido en la peticion			
		if u then
			u.delete
			AccessResult.new(ReturnCode::GENEVENT,"Usuario eliminado").to_json
		else 
			AccessResult.new(ReturnCode::RNOTFOUND,"No existe el usuario").to_json
		end
	else
		res.to_json
	end
end

#Todas las notas de un usuario
get '/apinotes/user/:idu/note' do
	res = userAuth(adminreq=false,loginreq=true,params[:idu])	
	if res.code == ReturnCode::CANEXEC then
		tasks = Task.where(user_id:params[:idu])
		if  tasks.length > 0 then
			tasks.to_json
		else
			AccessResult.new(ReturnCode::RNOTFOUND,"No hay notas").to_json
		end
	else
		res.to_json
	end
end

#Detalles nota
get '/apinotes/user/:idu/note/:idn' do
	res = userAuth(adminreq=false,loginreq=true,userid=params[:idu])	
	if res.code == ReturnCode::CANEXEC then
		task  = Task.where(user_id:params[:idu],id:params[:idn]).take
		if task then
			task.to_json
		else
			AccessResult.new(ReturnCode::RNOTFOUND,"La nota no existe").to_json
		end
	else
		res.to_json	
	end
end

#Crear nota
post '/apinotes/user/:idu/note' do
	res = userAuth(adminreq=false,loginreq=true,userid=params[:idu])
	if res.code == ReturnCode::CANEXEC then
		u = User.where(id:params[:idu]).take
		if u then
			description = plan_date = first_plan_date = priority = type = nil
			description = params[:description]
			#creation_date = params[:creation_date]
			creation_date = Time.now.strftime("%Y-%m-%d %I:%M:%S")
			plan_date =  params[:plan_date]
			if plan_date then
				first_plan_date = plan_date
			end
			priority = params[:priority]
			finished = 0 
			type = params[:type]
			user_id = params[:idu]
			if description then
				task = Task.new
				task.description = description
				task.creation_date = creation_date
				task.plan_date = plan_date
				task.first_plan_date = first_plan_date
				task.priority = priority
				task.finished = finished
				task.ntype = type
				task.user_id = user_id
				task.save
				AccessResult.new(ReturnCode::GENEVENT,"Nota creada").to_json
			else
				AccessResult.new(ReturnCode::GENEXCEPT,"Faltan parametros").to_json
			end
		else
			AccessResult.new(ReturnCode::GENEXCEPT,"No existe el usuario").to_json
		end
	else
		res.to_json
	end
end

#Actualizar nota
put '/apinotes/user/:idu/note/:idn'  do
	res = userAuth(adminreq=false,loginreq=true,userid=params[:idu])	
	if res.code == ReturnCode::CANEXEC then
		task  = Task.where(user_id:params[:idu],id:params[:idn]).take
		if task then
			description = params[:description]
			plan_date =  params[:plan_date]
			priority = params[:priority]
			finished = params[:finished] 
			type = params[:type]
			if description then
				task.update(description:description)
			end
			if plan_date then
				task.update(plan_date:plan_date)
				if not task.first_plan_date.to_s.length then
					task.update(first_plan_date:plan_date)
				end
			end
			if priority then
				task.update(priority:priority)
			end
			if finished then
				task.update(finished:finished)
			end
			if type then
				task.update(ntype:type)
			end
			AccessResult.new(ReturnCode::GENEVENT,"Nota actualizada").to_json
		else
			AccessResult.new(ReturnCode::RNOTFOUND,"No existe la nota").to_json
		end
	else
		res.to_json
	end
end

#Eliminar todas las notas de un usuario
delete '/apinotes/user/:idu/note' do	
	res = userAuth(adminreq=false,loginreq=true,userid=params[:idu])	
	if res.code == ReturnCode::CANEXEC then
		Task.where(user_id:params[:idu]).delete_all
		AccessResult.new(ReturnCode::GENEVENT,"Todas las notas han sido elminadas").to_json
	else
		res.to_json
	end
end

#Eliminar nota
delete '/apinotes/user/:idu/note/:idn' do
	res = userAuth(adminreq=false,loginreq=true,userid=params[:idu])	
	if res.code == ReturnCode::CANEXEC then
		task  = Task.where(user_id:params[:idu],id:params[:idn]).take
		if task then
			task.delete
			AccessResult.new(ReturnCode::GENEVENT,"Nota elminada").to_json
		else
			AccessResult.new(ReturnCode::GENEXCEPT,"Nota no encontrada").to_json
		end
	else
		res.to_json
	end
end




