import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import App from './App.jsx';

describe('App', () => {
  it('renders the heading', () => {
    render(<App />);
    expect(
      screen.getByRole('heading', { name: /fsl devops challenge/i })
    ).toBeInTheDocument();
  });

  it('renders the environment label from the (mocked) Vite env', () => {
    render(<App />);
    expect(screen.getByTestId('env-label')).toHaveTextContent('Local');
  });

  it('increments the click counter when the button is clicked', () => {
    render(<App />);
    const button = screen.getByRole('button', { name: /clicked 0 times/i });
    fireEvent.click(button);
    expect(
      screen.getByRole('button', { name: /clicked 1 time\b/i })
    ).toBeInTheDocument();
  });
});
