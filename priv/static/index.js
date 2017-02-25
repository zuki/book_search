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
        <h1>Phoenix+React BookSearch Sample</h1>
        <div className='col-md-3'>
          <Submit onSubmit={this.handleSearchSubmit.bind(this)}/>
        </div>
        <div className='col-md-9'>
          {books}
        </div>
      </div>
    );
  }
}

const Book = props => {
  return (
    <div className='panel panel-default'>
      <div className='panel-heading'>
        <h4 className='panel-title'>{props.data.title}</h4>
      </div>
      <div className='panel-body'>
        {props.data.author}
      </div>
    </div>
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
      <form onSubmit={this.handleSubmit.bind(this)}>
        <div className='form-group'>
          <input className='form-control' type='text' placeholder='検索クエリ' value={this.state.query} onChange={this.handleQueryChange.bind(this)}/>
        </div>
        <input className='btn btn-default pull-right' type='submit' value='検索' />
      </form>
    );
  }
}

render(<BookSearch />, document.querySelector('.main'));
