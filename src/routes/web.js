import express from 'express'
import { handHelloWorld, handleCreateUser, handleAddUser, handleTeam } from '../controller/homeController'
const router = express.Router()

const initWebRoute = (app) => {
    router.get('/', handHelloWorld),

    router.get('/team', handleTeam)
    router.get('/users',handleAddUser)
    router.post('/users/create-user',handleCreateUser)
    // router.post('/delete-user/:id',handeDeleteUser)
    // router.get('/update-user/:id',getUpdateUserPage=()=>{res.send('cac')})

    return app.use('/', router)
}

export default initWebRoute;