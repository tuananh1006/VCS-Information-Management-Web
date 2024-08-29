import userService from '../service/userService'
import {selectDatabase,performModify} from '../config/connectDB'

const axios = require('axios');


const moment = require('moment')

const handleHomePage=(req,res)=>{
    return res.render('homepage.ejs')
}

const handleScheduler=async (req,res)=>{
        var query='select * from LICHTHIDAU'
        var result=await selectDatabase(query)
        console.log(result[0]['ĐỘI 1'])
        // result.forEach(row => {
        //     if (row['NGÀY THI ĐẤU']){
        //     row['NGÀY THI ĐẤU'] = moment(row['NGÀY THI ĐẤU']).format('DD-MM-YYYY');
        //     }
        // })
        return res.render('scheduler.ejs',{result})
}

const handleRanking=async(req,res)=>{
    var query = 'SELECT * FROM RankingsBySeason'
    var result=await selectDatabase(query)
    var query2='select seasonID,seasonName from SEASON'
    var result2=await selectDatabase(query2)
    return res.render('ranking.ejs',{result,result2})
}

const handleTeams=async(req,res)=>{
    var query='select * from TEAM_ESPORT'
    var result=await selectDatabase(query)
    return res.render('teams.ejs',{result})
}

const handlePlayers= async (req,res)=>{
    var query='select * from PLAYERINFO'
    var result =await selectDatabase(query)
    // result.forEach(row => {
    //     if (row.DATESTART){
    //     row.DATESTART = moment(row.DATESTART).format('DD-MM-YYYY');
    //     }
    //     if (row.DATEEND)
    //     row.DATEEND = moment(row.DATEEND).format('DD-MM-YYYY');
    // });
    //console.log(result[0]['NICKNAME'])
    return res.render('players.ejs', {result})
}

const handlePrintResult = async (req, res) => {
    const { teamoneID, teamtwoID, day_code, seasonID } = req.body;

    try {
        const response = await axios.post('http://localhost:5000/predict', {
            features: [teamoneID, teamtwoID, day_code, seasonID]
        });

        var query = `EXEC GetTop5MatchResults @TeamOneID =${teamoneID}, @TeamTwoID = ${teamtwoID}`
        let data = await selectDatabase(query);
        data.forEach(row => {
            if (row.matchDate) {
                row.matchDate = moment(row.matchDate).format('DD-MM-YYYY');
            }
        });

        query = 'select teamName from TEAM_ESPORT where teamID=' + teamoneID;
        var teamonename = (await selectDatabase(query))[0].teamName;

        query = 'select teamName from TEAM_ESPORT where teamID=' + teamtwoID;
        var teamtwoname = (await selectDatabase(query))[0].teamName;

        query = 'EXEC CalculateWinRateRecentMatches @TeamID = ' + teamoneID;
        var winningPercentage1 = (await selectDatabase(query))[0].WinRate;
        if (winningPercentage1==null){
            winningPercentage1=0
        }
        else{
            winningPercentage1=winningPercentage1*100
        }
        query = 'EXEC CalculateWinRateRecentMatches @TeamID = ' + teamtwoID;
        var winningPercentage2 = (await selectDatabase(query))[0].WinRate;
        if (winningPercentage2==null){
            winningPercentage2=0
        }
        else{
            winningPercentage2=winningPercentage2*100
        }
        query = 'EXEC CalculateBayesProbability 22, 18'
        var bayesRate = await selectDatabase(query);
        console.log(bayesRate)
        var P1 = bayesRate[0].P1;
        var P2 = bayesRate[0].P2;
        if (P1==null){
            P1=0
        }
        else{
            P1=P1*100
        }
        if (P2==null){
            P2=0
        }
        else{
            P2=P2*100
        }
        console.log(P1)
        console.log(P2)
        let nameteamwin=teamonename
        const prediction = response.data.prediction[0];
        let message = '';
        let message2 = 'Win';
        if (prediction == 2) {
            message = '2-0';
        } else if (prediction == 1) {
            message = '2-1';
        } else if (prediction == -1) {
            message = '2-1';
            nameteamwin=teamtwoname
        } else if (prediction == -2) {
            message = '2-0';
            nameteamwin=teamtwoname

        }

        res.render('aipredict.ejs', {
            message,
            message2,
            teamonename,
            teamtwoname,
            winningPercentage1,
            winningPercentage2,
            P1,
            P2,
            nameteamwin,
            data
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Có lỗi xảy ra!');
    }
};


const handleAIPredict=(req,res)=>{
    res.render('form.ejs')
}

const handleInformation=(req,res)=>{
    res.render('information.ejs')
}
// 
module.exports={
    handleHomePage,handleScheduler,handleRanking,handleTeams,handlePlayers,handlePrintResult,handleAIPredict,handleInformation
}


// const handleTeam=(req,res)=>{
    //     var clubs=[{
    //         name:'Tun',
    //         wins:1,
    //         draws:1,
    //         losts:1,
    //         goalsFor:1,
    //         goalsAgainst:1,
    //         goalsDiff:1,
    //         point:1
    //     }]
    //     return res.render('team.ejs',{clubs})
    // }
    
    // const handleAddUser=(req,res)=>{
    //     let userList=userService.getUserList()
    //     return res.render('user-add.ejs',{userList})
    // }
    
    
    // const handleCreateUser=(req,res)=>{
    //     let email=req.body.email
    //     let password=req.body.password
    //     let username=req.body.username
    
    //     return res.redirect('/users/')
    // }