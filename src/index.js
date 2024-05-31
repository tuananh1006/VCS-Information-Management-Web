require("dotenv").config()
import express from 'express'
import configViewEngine from './config/viewEngine'
import initWebRoute from './routes/web'
const app = express();


configViewEngine(app)

initWebRoute(app)


const PORT = process.env.PORT || 8080
app.listen(PORT, () => {
    console.log(`Server running on ${PORT}`)
})
