require 'active_record'
require 'mysql2'
require 'sinatra'
require 'json'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection adapter:"mysql2",database:"TASKAPP",
								username:"root",host:"localhost",
								password:"",encoding:"utf8"
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

class Type < ActiveRecord::Base

end

class Task < ActiveRecord::Base
	belongs_to:Type
end



#Todas las notas
get "/apinotes/note" do
	u = userlogin(request)
	if u then
		if u.role == "admin" then
			if Task.all.length > 0 then
				Task.all.to_json
			else
				"No hay notas"
			end
		else
			"No esta autorizado"
		end
	else
		"Debe iniciar sesion"
	end
end

#Detalles nota
get "/apinotes/note/:id" do
	u = userlogin(request)
	if u then
		task  = Task.where(id:params[:id]).take
		if task then
			if u.id == task.user_id
				task.to_json
			else
				"No esta autorizado"				
			end
		else
			"La nota no existe"
		end
	else
		"Debe iniciar sesion"	
	end
end

#Crear nota
post "/apinotes/note" do
	task = Task.create(description: params[:description], creation_date: params[:creation_date], plan_date: params[:plan_date], first_plan_date: params[:first_plan_date], priority: params[:priority], finished: params[:finished], type: params[:type], user_id: params[:user_id])
end

#eliminar nota
delete "/apinotes/note/:id" do

	u = userlogin(request)
	if u then
		if task then
			task = Task.find_by(id: params[:id])
			if u.id = task.user_id then
				task.destroy
			else
				"No esta autorizado"
			end
		else
			"La nota no existe"
		end
	else
		"Debe iniciar sesion"
	end
end

#actualizar nota
put "/apinotes/note/:id"  do

	u = userlogin(request)
	if u then
		task = Task.find_by(id: params[:id])
		if task then
			if u.id == task.user.id then
		#task.update(descripcion: params[:descripcion], fecha_creacion: params[:fecha_creacion], fecha_plan: params[:fecha_plan], fecha_p_plan: params[:fecha_p_plan], prioridad: params[:prioridad], terminada: params[:terminada], type_id: params[:type_id], user_id: params[:user_id])
				description = params[:description]
				creation_date = params[:creation_date]
				plan_date =  params[:plan_date]
				first_plan_date = params[:first_plan_date]
				priority = params[:priority]
				terminada = params[:finished] 
				type = params[:type]
				user_id = params[:user_id]
				if description then
					task.update(description:description)
				end
				if creation_date then
					task.update(creation_date:creation_date)
				end
				if plan_date then
					task.update(plan_date:plan_date)
				end
				if first_plan_date then
					task.update(first_plan_date:first_plan_date)
				end
				if priority then
					task.update(priority:priority)
				end
				if finished then
					task.update(finished:finished)
				end
				if type then
					task.update(type:type)
				end
				if user_id then
					task.update(user_id:user_id)
				end
				"Nota actualizada"
			else
				"No esta autorizado"
			end
		else
			"La nota no existe"
		end
	else
		"Debe iniciar sesion"
	end	
end



