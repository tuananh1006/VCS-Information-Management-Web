import express from 'express'
import { handleHomePage,handleScheduler, handleCreateUser, handleTeam} from '../controller/homeController'
const router = express.Router()

const initWebRoute = (app) => {
    router.get('/', handleHomePage),
    router.get('/scheduler',handleScheduler)
    // router.get('/ranking',handleRanking)
    router.get('/team', handleTeam)
    router.post('/users/create-user',handleCreateUser)
    // router.post('/delete-user/:id',handeDeleteUser)
    // router.get('/update-user/:id',getUpdateUserPage=()=>{res.send('cac')})

    return app.use('/', router)
}

export default initWebRoute;