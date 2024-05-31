import express from 'express'
import { handHelloWorld, handleTeam } from '../controller/homeController'
const router = express.Router()

const initWebRoute = (app) => {
    router.get('/', handHelloWorld),

    router.get('/team', handleTeam)


    return app.use('/', router)
}

export default initWebRoute;