import React, {Component} from 'react';
import {render} from 'react-dom';
import request from 'superagent';

class BookSearch extends Component {
  constructor(props) {
    super(props);
    this.state = {
      data: []
    };
  }

  handleSearchSubmit(query) {
    request
      .get('/api/books?query='+query)
      .set('Accept', 'application/json')
      .set('Content-type', 'application/json')
      .end((err, res) => {
        this.setState({data: res.body.data.reverse()});
      });
  }

  render() {
    const books = this.state.data.map((book, i) => {
      return (
        <Book data={book} key={i} />
      );
    });

    return (
      <div className='container'>
        <h1 className="text-center">BookSearch</h1>
        <Submit onSubmit={this.handleSearchSubmit.bind(this)}/>
        <Books data={this.state.data}/>
      </div>
    );
  }
}

class Books extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    const books = this.props.data.map((book, i) => {
      return (
        <Book data={book} key={i} />
      );
    });

    return (
      <div className='row' style={{marginTop:'15px'}}>
        <div className="col-md-10 col-md-offset-1">
          <div className='panel panel-success'>
            <div className='panel-heading text-center'>検索結果</div>
            <ul className='list-group'>
              {books}
            </ul>
          </div>
        </div>
      </div>
    );
  }
}

const Book = props => {
  return (
    <li className='list-group-item'>
      <h4>
        <a href={props.data.url}>
          {props.data.title}
        </a>
      </h4>
      &nbsp;&nbsp;{props.data.author} {props.data.publisher} {props.data.date} ({props.data.isbn})
    </li>
  );
};

class Submit extends Component {
  constructor(props) {
    super(props);
    this.state = {query: ''};
  }

  handleSubmit(e) {
    e.preventDefault();
    //const field = this.state.field.trim();
    const query = this.state.query.trim();
    if (!query) {
      return;
    }
    this.props.onSubmit(query);
    this.setState({query: ''});
  }

  handleQueryChange(e) {
    this.setState({query: e.target.value});
  }


  render() {
    return (
      <div className='row'>
        <div className="col-md-10 col-md-offset-1">
          <form onSubmit={this.handleSubmit.bind(this)}>
            <div className='input-group'>
              <input className='form-control' type='text' placeholder='検索クエリ' value={this.state.query} onChange={this.handleQueryChange.bind(this)}/>
              <span className='input-group-btn'>
                <button className='btn btn-primary' type='submit'>検索</button>
              </span>
            </div>
          </form>
        </div>
      </div>
    );
  }
}

render(<BookSearch />, document.querySelector('.main'));
