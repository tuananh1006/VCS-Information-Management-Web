import express from 'express'
import { handHelloWorld, handleCreateUser, handleLogin, handleTeam } from '../controller/homeController'
const router = express.Router()

const initWebRoute = (app) => {
    router.get('/', handHelloWorld),

    router.get('/team', handleTeam)
    router.get('/login',handleLogin)
    router.post('/users/create-user',handleCreateUser)
    return app.use('/', router)
}

export default initWebRoute;