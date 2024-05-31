require("dotenv").config()
import express from 'express'
import configViewEngine from './config/viewEngine'
import initWebRoute from './routes/web'
import bodyParser from 'body-parser';
const app = express();


configViewEngine(app)

app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: false }))

initWebRoute(app)


const PORT = process.env.PORT || 8080
app.listen(PORT, () => {
    console.log(`Server running on ${PORT}`)
})
